///|
fn main {
  // 测试数据
  let test_data = "Finite State Entropy and Huffman coding implementation in MoonBit language. This is a comprehensive test of compression algorithms.".to_bytes()
  
  println("=== Finite State Entropy (FSE) 和 Huffman 编码库测试 ===")
  println("")
  
  // 数据特征分析
  println("1. 数据特征分析:")
  println(@lib.analyze_data_simple(test_data))
  println("")
  
  // 自动压缩测试
  println("2. 自动压缩测试:")
  let auto_result = @lib.auto_compress_simple(test_data)
  println("原始大小: " + test_data.length().to_string() + " bytes")
  println("压缩后大小: " + auto_result.data.length().to_string() + " bytes")
  println("压缩比: " + auto_result.ratio.to_string())
  println("")
  
  // 分别测试Huffman和FSE
  println("3. Huffman编码测试:")
  let huffman_compressed = @lib.simple_huffman_compress(test_data)
  let huffman_decompressed = @lib.simple_huffman_decompress(huffman_compressed)
  println("压缩后大小: " + huffman_compressed.length().to_string() + " bytes")
  println("解压缩验证: " + (huffman_decompressed.length() == test_data.length()).to_string())
  println("")
  
  println("4. FSE编码测试:")
  let fse_compressed = @lib.simple_fse_compress(test_data)
  let fse_decompressed = @lib.simple_fse_decompress(fse_compressed)
  println("压缩后大小: " + fse_compressed.length().to_string() + " bytes")
  println("解压缩验证: " + (fse_decompressed.length() == test_data.length()).to_string())
  println("")
  
  // 智能解压缩测试
  println("5. 智能解压缩测试:")
  let smart_huffman = @lib.smart_decompress_simple(huffman_compressed)
  let smart_fse = @lib.smart_decompress_simple(fse_compressed)
  println("Huffman智能解压缩: " + (smart_huffman.length() == test_data.length()).to_string())
  println("FSE智能解压缩: " + (smart_fse.length() == test_data.length()).to_string())
  println("")
  
  // 测试重复数据
  println("6. 重复数据测试:")
  let repeated_data = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA".to_bytes()
  let repeated_compressed = @lib.simple_huffman_compress(repeated_data)
  let repeated_decompressed = @lib.simple_huffman_decompress(repeated_compressed)
  println("重复数据压缩比: " + (repeated_data.length().to_double() / repeated_compressed.length().to_double()).to_string())
  println("重复数据解压缩验证: " + (repeated_decompressed.length() == repeated_data.length()).to_string())
  println("")
  
  println("=== 测试完成 ===")
}
