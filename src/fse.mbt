/// FSE压缩模块
/// 实现有限状态熵压缩算法

///|
/// 简单FSE压缩
pub fn simple_fse_compress(data : Bytes) -> Bytes {
  let options = create_default_fse_options()
  match fse_compress_advanced(data, options) {
    CompressionResult::Success(compressed) => compressed
    CompressionResult::SingleSymbol(compressed) => compressed
    _ => data // 如果失败，返回原数据
  }
}

///|
/// 简单FSE解压缩
pub fn simple_fse_decompress(data : Bytes) -> Bytes {
  match fse_decompress_advanced(data) {
    CompressionResult::Success(decompressed) => decompressed
    _ => data // 如果失败，返回原数据
  }
}

///|
/// 高级FSE压缩
pub fn fse_compress_advanced(
  data : Bytes,
  options : FSEOptions,
) -> CompressionResult {
  if data.length() == 0 {
    return CompressionResult::NotCompressible
  }

  // 统计符号频率
  let (count, max_symbol, _max_freq) = count_histogram(
    data,
    options.max_symbol_value,
  )

  // 检查单符号情况
  let (is_single, single_symbol) = is_single_symbol(count, max_symbol)
  if is_single {
    return compress_rle(data, single_symbol)
  }

  // 检查是否有足够的符号
  let unique = count_unique_symbols(count, max_symbol)
  if unique == 0 {
    return CompressionResult::NotCompressible
  }

  // 最小可用版本：使用固定比特宽度对符号进行位打包
  // 1. 计算表示 [0, max_symbol] 所需的比特数
  let nb_bits = if max_symbol <= 1 {
    1
  } else {
    highbit32(max_symbol.to_uint()) + 1
  }

  // 如果需要 >=8bit，说明无法比原始字节更紧凑，这里直接认为不可压缩
  if nb_bits >= 8 {
    return CompressionResult::NotCompressible
  }

  // 2. 使用位流打包数据
  let bit_stream = BitCStream::new(data.length())
  for i in 0..<data.length() {
    let symbol_val = data[i].to_uint64()
    bit_stream.add_bits(symbol_val, nb_bits)
  }
  let packed : Bytes = bit_stream.close()

  // 3. 如果加上头部后不比原始小，则认为不可压缩
  let header_size = 7 // [magic][nb_bits][max_symbol][orig_len(4 bytes)]
  if header_size + packed.length() >= data.length() {
    return CompressionResult::NotCompressible
  }

  // 4. 构造输出格式：
  //    0: 0x02 (FSE 标记)
  //    1: nb_bits
  //    2: max_symbol
  //  3-6: 原始长度（大端）
  //    7..: 位打包后的数据
  let output : Array[Byte] = []
  output.push(0x02) // FSE标记
  output.push(nb_bits.to_byte())
  output.push(max_symbol.to_byte())

  let length = data.length()
  output.push((length >> 24).to_byte())
  output.push((length >> 16).to_byte())
  output.push((length >> 8).to_byte())
  output.push(length.to_byte())

  for i in 0..<packed.length() {
    output.push(packed[i])
  }

  CompressionResult::Success(Bytes::from_array(output))
}

///|
/// 高级FSE解压缩
pub fn fse_decompress_advanced(data : Bytes) -> CompressionResult {
  if data.length() < 1 {
    return CompressionResult::Error("数据太短")
  }

  // 检查RLE标记（需要至少3字节）
  if data[0] == 0x01 {
    return decompress_rle(data)
  }

  // 检查FSE标记（需要至少7字节）
  if data[0] == 0x02 {
    if data.length() < 7 {
      return CompressionResult::Error("FSE数据太短")
    }
    return decompress_fse(data)
  }
  CompressionResult::Error("未知的压缩格式")
}

///|
/// RLE压缩
fn compress_rle(data : Bytes, symbol : Int) -> CompressionResult {
  let result : Array[Byte] = []
  result.push(0x01) // RLE标记
  result.push(symbol.to_byte())
  let length = data.length()
  // 使用紧凑格式存储长度
  if length <= 255 {
    result.push(length.to_byte())
  } else {
    result.push(0xFF) // 特殊标记表示长度超过255
    result.push((length / 256).to_byte())
    result.push((length % 256).to_byte())
  }
  CompressionResult::SingleSymbol(Bytes::from_array(result))
}

///|
/// RLE解压缩
fn decompress_rle(data : Bytes) -> CompressionResult {
  if data.length() < 3 {
    return CompressionResult::Error("RLE数据太短")
  }
  let symbol = data[1]
  let length = if data[2] == 0xFF {
    // 长格式：长度超过255
    if data.length() < 5 {
      return CompressionResult::Error("RLE长格式数据太短")
    }
    data[3].to_int() * 256 + data[4].to_int()
  } else {
    // 短格式：长度在0-255之间
    data[2].to_int()
  }
  let result : Array[Byte] = Array::new(capacity=length)
  for _ in 0..<length {
    result.push(symbol)
  }
  CompressionResult::Success(Bytes::from_array(result))
}

///|
/// FSE解压缩实现
fn decompress_fse(data : Bytes) -> CompressionResult {
  if data.length() < 7 {
    return CompressionResult::Error("FSE数据太短")
  }

  let nb_bits = data[1].to_int()
  let _max_symbol = data[2].to_int()
  let length = (data[3].to_int() << 24) |
    (data[4].to_int() << 16) |
    (data[5].to_int() << 8) |
    data[6].to_int()

  if nb_bits <= 0 || nb_bits >= 8 {
    return CompressionResult::Error("不支持的FSE比特宽度")
  }
  if length < 0 {
    return CompressionResult::Error("FSE长度非法")
  }
  if data.length() == 7 {
    return CompressionResult::Error("FSE缺少压缩数据")
  }

  // 取压缩比特流部分
  let payload_len = data.length() - 7
  let mut bit_buffer : UInt64 = 0UL
  let mut bits_in_buffer = 0
  let mut byte_pos = 0

  // 预加载最多前8字节到 bit_buffer（与 BitCStream::close 写出的格式保持一致）
  let preload = if payload_len >= 8 { 8 } else { payload_len }
  for i in 0..<preload {
    let b = data[7 + i].to_uint64()
    bit_buffer = bit_buffer | (b << (i * 8))
    bits_in_buffer = bits_in_buffer + 8
  }
  byte_pos = preload

  let result : Array[Byte] = Array::new(capacity=length)

  for _ in 0..<length {
    // 确保缓冲中有足够的位
    while bits_in_buffer < nb_bits && byte_pos < payload_len {
      let b = data[7 + byte_pos].to_uint64()
      bit_buffer = bit_buffer | (b << bits_in_buffer)
      bits_in_buffer = bits_in_buffer + 8
      byte_pos = byte_pos + 1
    }
    if bits_in_buffer < nb_bits {
      return CompressionResult::Error("FSE比特流数据不完整")
    }

    let mask = (1UL << nb_bits) - 1UL
    let symbol_val = (bit_buffer & mask).to_int()
    if symbol_val < 0 || symbol_val > 255 {
      return CompressionResult::Error("FSE符号超出范围")
    }
    result.push(symbol_val.to_byte())
    bit_buffer = bit_buffer >> nb_bits
    bits_in_buffer = bits_in_buffer - nb_bits
  }

  if result.length() != length {
    return CompressionResult::Error("解压缩长度不匹配")
  }
  CompressionResult::Success(Bytes::from_array(result))
}
