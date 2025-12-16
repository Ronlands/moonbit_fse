/// 智能压缩模块
/// 自动选择最佳压缩方法

///|
/// 智能压缩（自动选择最佳方法）
pub fn smart_compress_advanced(data : Bytes) -> (CompressionResult, String) {
  let fse_options = create_default_fse_options()
  let huffman_options = create_default_huffman_options()

  // 尝试FSE压缩
  let fse_result = fse_compress_advanced(data, fse_options)
  let fse_size = match fse_result {
    CompressionResult::Success(bytes) => bytes.length()
    CompressionResult::SingleSymbol(bytes) => bytes.length()
    _ => data.length() + 1 // 比原数据大，表示失败
  }

  // 尝试Huffman压缩
  let huffman_result = huffman_compress_advanced(data, huffman_options)
  let huffman_size = match huffman_result {
    CompressionResult::Success(bytes) => bytes.length()
    _ => data.length() + 1 // 比原数据大，表示失败
  }

  // 选择最佳方法
  if fse_size <= huffman_size && fse_size < data.length() {
    (fse_result, "FSE")
  } else if huffman_size < data.length() {
    (huffman_result, "Huffman")
  } else {
    (CompressionResult::NotCompressible, "None")
  }
}

///|
/// 智能解压缩
pub fn smart_decompress_advanced(data : Bytes) -> CompressionResult {
  if data.length() == 0 {
    return CompressionResult::Error("空数据")
  }
  match data[0] {
    0x01 => fse_decompress_advanced(data) // RLE
    0x02 => fse_decompress_advanced(data) // FSE
    0x03 => huffman_decompress_advanced(data) // Huffman
    _ => {
      // 尝试基础Huffman解压缩
      let huffman_result = simple_huffman_decompress(data)
      if huffman_result.length() > 0 {
        CompressionResult::Success(huffman_result)
      } else {
        CompressionResult::Error("未知的压缩格式")
      }
    }
  }
}

///|
/// 简单智能解压缩（返回Bytes）
pub fn smart_decompress_simple(data : Bytes) -> Bytes {
  match smart_decompress_advanced(data) {
    CompressionResult::Success(decompressed) => decompressed
    _ => data // 如果失败，返回原数据
  }
}

///|
/// 自动压缩（返回SimpleResult）
pub fn auto_compress_simple(data : Bytes) -> SimpleResult {
  let (result, algo) = smart_compress_advanced(data)
  match result {
    CompressionResult::Success(compressed) => {
      let ratio = if data.length() > 0 {
        compressed.length().to_double() / data.length().to_double()
      } else {
        1.0
      }
      SimpleResult::{ data: compressed, ratio, algorithm: algo }
    }
    CompressionResult::SingleSymbol(compressed) => {
      let ratio = if data.length() > 0 {
        compressed.length().to_double() / data.length().to_double()
      } else {
        1.0
      }
      // 单符号场景，本质是 RLE
      SimpleResult::{ data: compressed, ratio, algorithm: "RLE" }
    }
    _ => SimpleResult::{ data, ratio: 1.0, algorithm: "None" }
  }
}

///|
/// 分析数据特征
pub fn analyze_data_simple(data : Bytes) -> String {
  if data.length() == 0 {
    return "数据为空，无法压缩"
  }
  let mut result = "数据分析:\n"
  result = result + "  数据长度: " + data.length().to_string() + " 字节\n"

  // 统计符号频率
  let freq : Array[Int] = []
  for i = 0; i < 256; i = i + 1 {
    freq.push(0)
  }
  for i = 0; i < data.length(); i = i + 1 {
    let byte_val = data[i].to_int()
    freq[byte_val] = freq[byte_val] + 1
  }

  // 计算唯一符号数量
  let mut unique_symbols = 0
  let mut max_freq = 0
  for i = 0; i < 256; i = i + 1 {
    if freq[i] > 0 {
      unique_symbols = unique_symbols + 1
      if freq[i] > max_freq {
        max_freq = freq[i]
      }
    }
  }
  result = result + "  唯一符号数: " + unique_symbols.to_string() + "\n"
  result = result + "  最大频率: " + max_freq.to_string() + "\n"

  // 计算熵
  let mut entropy = 0.0
  for i in 0..<256 {
    if freq[i] > 0 {
      let p = freq[i].to_double() / data.length().to_double()
      let log_p = log(p)
      let log_2 = log(2.0)
      entropy = entropy - p * (log_p / log_2)
    }
  }
  result = result + "  信息熵: " + entropy.to_string() + "\n"

  // 建议压缩方法
  if unique_symbols == 1 {
    result = result + "  建议: 使用RLE压缩\n"
  } else if entropy < 3.0 {
    result = result + "  建议: 使用FSE压缩\n"
  } else {
    result = result + "  建议: 使用Huffman压缩\n"
  }
  result
}
