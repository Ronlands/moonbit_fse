/// Huffman压缩模块
/// 实现Huffman编码压缩算法

///|
/// Huffman编码（完整版本）
priv struct HuffmanCode {
  length : Int // 码长
  code : UInt // 编码值
}

///|
/// Huffman树节点（用于构建Huffman树）
priv struct HuffmanNode {
  frequency : Int // 频率
  symbol : Int // 符号值（-1表示内部节点）
  left : HuffmanNode? // 左子节点
  right : HuffmanNode? // 右子节点
}

///|
/// 创建叶子节点
fn HuffmanNode::leaf(symbol : Int, frequency : Int) -> HuffmanNode {
  HuffmanNode::{ frequency, symbol, left: None, right: None }
}

///|
/// 创建内部节点
fn HuffmanNode::internal(
  left : HuffmanNode,
  right : HuffmanNode,
) -> HuffmanNode {
  HuffmanNode::{
    frequency: left.frequency + right.frequency,
    symbol: -1,
    left: Some(left),
    right: Some(right),
  }
}

///|
/// 基础Huffman压缩
pub fn simple_huffman_compress(data : Bytes) -> Bytes {
  let options = create_default_huffman_options()
  match huffman_compress_advanced(data, options) {
    CompressionResult::Success(compressed) => compressed
    CompressionResult::SingleSymbol(compressed) => compressed
    _ => data // 如果失败，返回原数据
  }
}

///|
/// 基础Huffman解压缩
pub fn simple_huffman_decompress(data : Bytes) -> Bytes {
  match huffman_decompress_advanced(data) {
    CompressionResult::Success(decompressed) => decompressed
    _ => data // 如果失败，返回原数据
  }
}

///|
/// 高级Huffman压缩
pub fn huffman_compress_advanced(
  data : Bytes,
  options : HuffmanOptions,
) -> CompressionResult {
  if data.length() == 0 {
    return CompressionResult::NotCompressible
  }

  // 统计符号频率
  let (count, max_symbol, _) = count_histogram(data, options.max_symbol_value)

  // 检查单符号情况
  let (is_single, single_symbol) = is_single_symbol(count, max_symbol)
  if is_single {
    return compress_huffman_rle(data, single_symbol)
  }

  // 检查唯一符号数
  let unique = count_unique_symbols(count, max_symbol)
  if unique <= 1 {
    return CompressionResult::NotCompressible
  }

  // 构建Huffman树和编码
  let codes = build_huffman_codes(count, max_symbol)

  // 创建头部输出
  let header : Array[Byte] = []
  header.push(0x03) // Huffman标记
  header.push(max_symbol.to_byte())

  // 写入原始数据长度（4字节）
  let length = data.length()
  header.push((length >> 24).to_byte())
  header.push((length >> 16).to_byte())
  header.push((length >> 8).to_byte())
  header.push(length.to_byte())

  // 存储码长（压缩的）
  write_code_lengths(header, codes, max_symbol)

  // 使用位流压缩实际数据
  let compressed_data = compress_with_codes(data, codes)

  // 合并头部和压缩数据
  let output : Array[Byte] = []
  for i in 0..<header.length() {
    output.push(header[i])
  }
  for i in 0..<compressed_data.length() {
    output.push(compressed_data[i])
  }
  let result = Bytes::from_array(output)

  // 检查压缩效果
  if result.length() >= data.length() {
    return CompressionResult::NotCompressible
  }
  CompressionResult::Success(result)
}

///|
/// 写入码长到缓冲区
fn write_code_lengths(
  output : Array[Byte],
  codes : Array[HuffmanCode],
  max_symbol : Int,
) -> Unit {
  // 简化版本：直接写入每个符号的码长
  for i = 0; i <= max_symbol; i = i + 1 {
    output.push(codes[i].length.to_byte())
  }
}

///|
/// 使用Huffman编码压缩数据
fn compress_with_codes(data : Bytes, codes : Array[HuffmanCode]) -> Bytes {
  let bit_stream = BitCStream::new(data.length())

  // Huffman编码从前向后编码，解码时从前向后读取
  for i = 0; i < data.length(); i = i + 1 {
    let symbol = data[i].to_int()
    let code = codes[symbol]
    if code.length > 0 {
      // 写入Huffman编码
      bit_stream.add_bits(code.code.to_uint64(), code.length)
    }
  }

  // 关闭位流
  bit_stream.close()
}

///|
/// 高级Huffman解压缩
pub fn huffman_decompress_advanced(data : Bytes) -> CompressionResult {
  if data.length() < 1 {
    return CompressionResult::Error("数据太短")
  }

  // 检查RLE标记（需要至少3字节）
  if data[0] == 0x01 {
    return decompress_huffman_rle(data)
  }

  // 检查普通Huffman标记（需要至少6字节）
  if data[0] == 0x03 {
    if data.length() < 6 {
      return CompressionResult::Error("Huffman数据太短")
    }
    return decompress_huffman(data)
  }
  CompressionResult::Error("未知的压缩格式")
}

///|
/// 构建Huffman编码（使用真正的Huffman算法）
fn build_huffman_codes(
  count : Array[Int],
  max_symbol : Int,
) -> Array[HuffmanCode] {
  let codes : Array[HuffmanCode] = Array::new(capacity=max_symbol + 1)

  // 收集所有非零频率的符号
  let nodes : Array[HuffmanNode] = []
  for i = 0; i <= max_symbol; i = i + 1 {
    if count[i] > 0 {
      nodes.push(HuffmanNode::leaf(i, count[i]))
    }
  }

  // 如果只有一个符号，特殊处理
  if nodes.length() == 0 {
    for i = 0; i <= max_symbol; i = i + 1 {
      codes.push(HuffmanCode::{ length: 0, code: 0 })
    }
    return codes
  }
  if nodes.length() == 1 {
    // 单符号：使用1位编码
    for i = 0; i <= max_symbol; i = i + 1 {
      if count[i] > 0 {
        codes.push(HuffmanCode::{ length: 1, code: 0 })
      } else {
        codes.push(HuffmanCode::{ length: 0, code: 0 })
      }
    }
    return codes
  }

  // 构建Huffman树
  let root = build_huffman_tree(nodes)

  // 从树中提取码长
  let lengths : Array[Int] = Array::new(capacity=max_symbol + 1)
  for i = 0; i <= max_symbol; i = i + 1 {
    lengths.push(0)
  }
  extract_code_lengths(root, 0, lengths)

  // 生成规范Huffman编码
  generate_canonical_codes(lengths, max_symbol, codes)
  codes
}

///|
/// 构建Huffman树（使用优先队列模拟）
fn build_huffman_tree(nodes : Array[HuffmanNode]) -> HuffmanNode {
  let mut queue = nodes.copy()

  // 持续合并最小的两个节点
  while queue.length() > 1 {
    // 排序以获取最小的两个节点（使用冒泡排序）
    sort_nodes(queue)
    let left = queue[0]
    let right = queue[1]

    // 移除前两个节点
    let new_queue : Array[HuffmanNode] = []
    for i = 2; i < queue.length(); i = i + 1 {
      new_queue.push(queue[i])
    }

    // 创建新的内部节点并添加回队列
    let internal = HuffmanNode::internal(left, right)
    new_queue.push(internal)
    queue = new_queue
  }
  queue[0]
}

///|
/// 对节点数组排序（简单的冒泡排序）
fn sort_nodes(nodes : Array[HuffmanNode]) -> Unit {
  let n = nodes.length()
  for i = 0; i < n - 1; i = i + 1 {
    for j = 0; j < n - i - 1; j = j + 1 {
      if nodes[j].frequency > nodes[j + 1].frequency {
        let temp = nodes[j]
        nodes[j] = nodes[j + 1]
        nodes[j + 1] = temp
      }
    }
  }
}

///|
/// 从Huffman树提取码长
fn extract_code_lengths(
  node : HuffmanNode,
  depth : Int,
  lengths : Array[Int],
) -> Unit {
  if node.symbol >= 0 {
    // 叶子节点：记录码长
    lengths[node.symbol] = depth
  } else {
    // 内部节点：递归处理子节点
    match node.left {
      Some(left) => extract_code_lengths(left, depth + 1, lengths)
      None => ()
    }
    match node.right {
      Some(right) => extract_code_lengths(right, depth + 1, lengths)
      None => ()
    }
  }
}

///|
/// 生成规范Huffman编码
fn generate_canonical_codes(
  lengths : Array[Int],
  max_symbol : Int,
  codes : Array[HuffmanCode],
) -> Unit {
  // 找出最大码长
  let mut max_length = 0
  for i = 0; i <= max_symbol; i = i + 1 {
    if lengths[i] > max_length {
      max_length = lengths[i]
    }
  }

  // 计算每个长度的符号数量
  let bl_count : Array[Int] = Array::new(capacity=max_length + 1)
  for i = 0; i <= max_length; i = i + 1 {
    bl_count.push(0)
  }
  for i = 0; i <= max_symbol; i = i + 1 {
    bl_count[lengths[i]] = bl_count[lengths[i]] + 1
  }

  // 计算每个长度的起始码值
  let next_code : Array[UInt] = Array::new(capacity=max_length + 1)
  for i = 0; i <= max_length; i = i + 1 {
    next_code.push(0)
  }
  let mut code : UInt = 0
  for bits = 1; bits <= max_length; bits = bits + 1 {
    code = (code + bl_count[bits - 1].reinterpret_as_uint()) << 1
    next_code[bits] = code
  }

  // 为每个符号分配编码
  for i = 0; i <= max_symbol; i = i + 1 {
    let len = lengths[i]
    if len > 0 {
      // 规范码是MSB-first，但位流是LSB-first，所以需要反转
      let canonical_code = next_code[len]
      let reversed_code = bit_reverse(canonical_code, len)
      codes.push(HuffmanCode::{ length: len, code: reversed_code })
      next_code[len] = next_code[len] + 1
    } else {
      codes.push(HuffmanCode::{ length: 0, code: 0 })
    }
  }
}

///|
/// 位反转：将n位的值进行位反转
fn bit_reverse(value : UInt, nbits : Int) -> UInt {
  let mut result : UInt = 0
  let mut val = value
  for _ in 0..<nbits {
    result = (result << 1) | (val & 1)
    val = val >> 1
  }
  result
}

///|
/// Huffman RLE压缩
fn compress_huffman_rle(data : Bytes, symbol : Int) -> CompressionResult {
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
/// Huffman RLE解压缩
fn decompress_huffman_rle(data : Bytes) -> CompressionResult {
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
/// Huffman解压缩实现
fn decompress_huffman(data : Bytes) -> CompressionResult {
  if data.length() < 6 {
    return CompressionResult::Error("Huffman数据太短")
  }
  let max_symbol = data[1].to_int()
  let length = (data[2].to_int() << 24) |
    (data[3].to_int() << 16) |
    (data[4].to_int() << 8) |
    data[5].to_int()

  // 读取码长
  let header_size = 6 + max_symbol + 1
  if data.length() < header_size {
    return CompressionResult::Error(
      "头部数据不完整：需要" +
      header_size.to_string() +
      "，实际" +
      data.length().to_string(),
    )
  }
  let lengths : Array[Int] = []
  for i = 0; i <= max_symbol; i = i + 1 {
    lengths.push(data[6 + i].to_int())
  }

  // 从码长重建Huffman编码
  let codes = rebuild_codes_from_lengths(lengths, max_symbol)

  // 验证codes是否正确构建
  if codes.length() != max_symbol + 1 {
    return CompressionResult::Error("编码表长度错误")
  }

  // 解压缩数据（使用解码树，避免复杂查表边界问题）
  let compressed_start = header_size
  let compressed_length = data.length() - compressed_start
  if compressed_length == 0 {
    return CompressionResult::Error("压缩数据为空")
  }
  let payload : Array[Byte] = []
  for i = 0; i < compressed_length; i = i + 1 {
    payload.push(data[compressed_start + i])
  }
  match
    decompress_with_tree(
      Bytes::from_array(payload),
      codes,
      max_symbol,
      length,
    ) {
    Some(result) => CompressionResult::Success(result)
    None =>
      CompressionResult::Error(
        "位流解码失败（可能是解码表或位流问题）",
      )
  }
}

///|
/// 从码长重建Huffman编码
fn rebuild_codes_from_lengths(
  lengths : Array[Int],
  max_symbol : Int,
) -> Array[HuffmanCode] {
  let codes : Array[HuffmanCode] = []

  // 使用与压缩时相同的算法生成规范编码
  generate_canonical_codes(lengths, max_symbol, codes)
  codes
}

///|
/// 解码表条目
priv struct DecodeEntry {
  symbol : Int // 符号
  length : Int // 码长
}

///| 构建解码表（使用查找表加速解码）

///|
/// 返回 (解码表, table_bits)
fn build_decode_table(
  codes : Array[HuffmanCode],
  max_symbol : Int,
) -> (Array[DecodeEntry], Int) {
  // 找出最大码长
  let mut max_length = 0
  for i = 0; i <= max_symbol; i = i + 1 {
    if codes[i].length > max_length {
      max_length = codes[i].length
    }
  }

  // 创建解码表（使用有限大小以节省内存）
  let table_bits = if max_length > 10 { 10 } else { max_length }
  let table_size = 1 << table_bits
  let decode_table : Array[DecodeEntry] = []
  for _ in 0..<table_size {
    decode_table.push(DecodeEntry::{ symbol: -1, length: 0 })
  }

  // 填充解码表
  // 对于LSB-first位流，直接填充每个符号的码
  for symbol = 0; symbol <= max_symbol; symbol = symbol + 1 {
    let code = codes[symbol]
    if code.length > 0 && code.length <= table_bits {
      // 对于码长小于table_bits的短码，需要复制到所有可能的高位组合
      let code_val = code.code.reinterpret_as_int()
      let replications = 1 << (table_bits - code.length)
      for i = 0; i < replications; i = i + 1 {
        let idx = code_val | (i << code.length)
        if idx >= 0 && idx < decode_table.length() {
          // 用当前符号填充（后面的会覆盖前面的，但实际上不应该有冲突）
          decode_table[idx] = DecodeEntry::{ symbol, length: code.length }
        }
      }
    }
  }
  (decode_table, table_bits)
}

///|
/// 使用解码表解压缩数据
fn decompress_with_table(
  compressed : Bytes,
  decode_table : Array[DecodeEntry],
  table_bits : Int,
  output_length : Int,
) -> Bytes? {
  if compressed.length() == 0 {
    return None
  }
  let result : Array[Byte] = []
  
  // 简化的位流解码器
  let mut bit_buffer : UInt64 = 0UL
  let mut bits_in_buffer = 0
  let mut byte_pos = 0
  let mask = (1 << table_bits) - 1

  // 初始化：加载前8字节
  for i in 0..<8 {
    if i < compressed.length() {
      bit_buffer = bit_buffer | (compressed[i].to_uint64() << (i * 8))
      bits_in_buffer = bits_in_buffer + 8
    }
  }
  byte_pos = if compressed.length() >= 8 { 8 } else { compressed.length() }
  
  // 解码所有符号
  let mut decode_count = 0
  let mut last_valid_pos = result.length()
  while result.length() < output_length {
    decode_count = decode_count + 1
    // 防止无限循环
    if decode_count > output_length * 2 {
      return None
    }

    // 确保有足够的位可用（至少需要32位）
    while bits_in_buffer < 32 && byte_pos < compressed.length() {
      bit_buffer = bit_buffer |
        (compressed[byte_pos].to_uint64() << bits_in_buffer)
      bits_in_buffer = bits_in_buffer + 8
      byte_pos = byte_pos + 1
    }

    // 检查是否有足够的位来查表
    if bits_in_buffer < 1 {
      // 完全没有位了，但还没解码完所有符号
      return None
    }

    // 查看前table_bits位
    let peek = (bit_buffer & mask.to_uint64()).to_int()
    if peek >= 0 && peek < decode_table.length() {
      let entry = decode_table[peek]
      if entry.symbol >= 0 && entry.length > 0 {
        // 检查是否有足够的位来消耗
        if bits_in_buffer < entry.length {
          // 尝试加载更多字节
          while bits_in_buffer < entry.length && byte_pos < compressed.length() {
            bit_buffer = bit_buffer |
              (compressed[byte_pos].to_uint64() << bits_in_buffer)
            bits_in_buffer = bits_in_buffer + 8
            byte_pos = byte_pos + 1
          }
          // 如果还是不够，说明数据不完整
          if bits_in_buffer < entry.length {
            return None
          }
        }

        // 找到有效符号
        result.push(entry.symbol.to_byte())
        last_valid_pos = result.length()

        // 消耗使用的位
        bit_buffer = bit_buffer >> entry.length
        bits_in_buffer = bits_in_buffer - entry.length
      } else {
        // 无效条目：解码表中该位置没有有效的符号
        // 这说明解码表有问题，或者位流数据损坏
        return None
      }
    } else {
      // peek超出范围（理论上不应该发生）
      return None
    }
  }

  // 成功解码
  Some(Bytes::from_array(result))
}

///|
/// 解码树节点
priv struct DecodeNode {
  mut left : Int  // 子节点索引，-1 表示不存在
  mut right : Int
  mut symbol : Int
  mut is_leaf : Bool
}

///|
/// 使用解码树解压缩数据（更接近参考实现的逐比特遍历，避免查表冲突）
fn decompress_with_tree(
  compressed : Bytes,
  codes : Array[HuffmanCode],
  max_symbol : Int,
  output_length : Int,
) -> Bytes? {
  if compressed.length() == 0 {
    return None
  }

  // 构建解码树
  let nodes : Array[DecodeNode] = []
  // 根节点索引为 0
  nodes.push(
    DecodeNode::{ left: -1, right: -1, symbol: -1, is_leaf: false },
  )

  for symbol = 0; symbol <= max_symbol; symbol = symbol + 1 {
    let code = codes[symbol]
    if code.length <= 0 {
      continue
    }
    // 代码是 LSB-first 存储的，因此从最低位开始往上遍历
    let mut node_index = 0
    let mut bit_pos = 0
    while bit_pos < code.length {
      // UInt 本身是无符号整型，直接 & 1 取最低位
      let bit = ((code.code >> bit_pos) & 1) == 1
      let next_index = if bit {
        nodes[node_index].right
      } else {
        nodes[node_index].left
      }
      if next_index == -1 {
        // 创建新节点
        let new_index = nodes.length()
        nodes.push(
          DecodeNode::{ left: -1, right: -1, symbol: -1, is_leaf: false },
        )
        if bit {
          nodes[node_index].right = new_index
        } else {
          nodes[node_index].left = new_index
        }
        node_index = new_index
      } else {
        node_index = next_index
      }
      bit_pos = bit_pos + 1
    }
    // 走完所有位，当前节点为叶子
    nodes[node_index].symbol = symbol
    nodes[node_index].is_leaf = true
  }

  // 逐比特解码
  let result : Array[Byte] = []
  let mut bit_buffer : UInt64 = 0UL
  let mut bits_in_buffer = 0
  let mut byte_pos = 0

  // 初始填充，与 BitCStream::close 对应（小端）
  while bits_in_buffer <= 56 && byte_pos < compressed.length() {
    bit_buffer = bit_buffer |
      (compressed[byte_pos].to_uint64() << bits_in_buffer)
    bits_in_buffer = bits_in_buffer + 8
    byte_pos = byte_pos + 1
  }

  while result.length() < output_length {
    // 如果缓冲区没有位了且没有更多字节，失败
    if bits_in_buffer == 0 && byte_pos >= compressed.length() {
      return None
    }

    // 确保至少还有 1 位可以读取
    if bits_in_buffer == 0 && byte_pos < compressed.length() {
      bit_buffer = bit_buffer |
        (compressed[byte_pos].to_uint64() << bits_in_buffer)
      bits_in_buffer = bits_in_buffer + 8
      byte_pos = byte_pos + 1
    }

    let mut node_index = 0
    // 从当前状态出发，一直走到叶子
    while !nodes[node_index].is_leaf {
      if bits_in_buffer == 0 {
        if byte_pos >= compressed.length() {
          return None
        }
        bit_buffer = bit_buffer |
          (compressed[byte_pos].to_uint64() << bits_in_buffer)
        bits_in_buffer = bits_in_buffer + 8
        byte_pos = byte_pos + 1
      }
      let bit = (bit_buffer & 1UL) == 1UL
      bit_buffer = bit_buffer >> 1
      bits_in_buffer = bits_in_buffer - 1

      let next_index = if bit {
        nodes[node_index].right
      } else {
        nodes[node_index].left
      }
      if next_index == -1 {
        return None
      }
      node_index = next_index
    }

    // 叶子节点：输出符号并回到根
    let symbol = nodes[node_index].symbol
    if symbol < 0 || symbol > 255 {
      return None
    }
    result.push(symbol.to_byte())
  }

  Some(Bytes::from_array(result))
}
