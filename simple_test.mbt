/// 简化版测试文件
/// 直接测试simple_fse.mbt中的函数

test "basic_compression" {
  let test_data = "Hello, World!".to_bytes()
  
  // 测试Huffman压缩
  let huffman_compressed = simple_huffman_compress(test_data)
  let huffman_decompressed = simple_huffman_decompress(huffman_compressed)
  
  // 验证解压缩正确性
  if huffman_decompressed.length() != test_data.length() {
    abort("Huffman解压缩长度不匹配")
  }
  
  // 测试FSE压缩
  let fse_compressed = simple_fse_compress(test_data)
  let fse_decompressed = simple_fse_decompress(fse_compressed)
  
  // 验证解压缩正确性
  if fse_decompressed.length() != test_data.length() {
    abort("FSE解压缩长度不匹配")
  }
}

test "repeated_data" {
  // 使用ASCII字符创建重复数据
  let repeated_data: Array[Byte] = []
  for i = 0; i < 200; i = i + 1 {
    repeated_data.push(65)  // ASCII 'A'
  }
  let repeated_bytes = Bytes::from_array(repeated_data)
  
  let compressed = simple_huffman_compress(repeated_bytes)
  let decompressed = simple_huffman_decompress(compressed)
  
  // 验证重复数据压缩
  if decompressed.length() != repeated_bytes.length() {
    abort("重复数据解压缩失败")
  }
  
  // 验证压缩效果
  if compressed.length() >= repeated_bytes.length() {
    abort("重复数据压缩效果不佳")
  }
}

test "data_analysis" {
  let test_data = "Test data for analysis.".to_bytes()
  let analysis = analyze_data_simple(test_data)
  
  // 验证分析结果包含关键信息
  if !analysis.contains("总字节数") {
    abort("分析结果缺少总字节数")
  }
  if !analysis.contains("建议") {
    abort("分析结果缺少建议")
  }
}
