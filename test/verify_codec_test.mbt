///| 验证编码解码一致性

test "verify_codec_consistency" {
  println("=== 验证Huffman编解码一致性 ===")
  
  // 创建简单的测试数据
  let test_sizes = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
  
  for size in test_sizes {
    let test_data : Array[Byte] = []
    for i = 0; i < size; i = i + 1 {
      test_data.push((i % 3).to_byte())
    }
    let data = Bytes::from_array(test_data)
    
    let options = @username/moonbit_fse/src.create_default_huffman_options()
    let result = @username/moonbit_fse/src.huffman_compress_advanced(data, options)
    
    match result {
      @username/moonbit_fse/src.CompressionResult::Success(compressed) => {
        let decomp_result = @username/moonbit_fse/src.huffman_decompress_advanced(compressed)
        match decomp_result {
          @username/moonbit_fse/src.CompressionResult::Success(decompressed) => {
            if decompressed.length() != data.length() {
              println("✗ 大小" + size.to_string() + ": 长度不匹配")
              abort("长度不匹配")
            }
            let mut match_count = 0
            for i = 0; i < data.length(); i = i + 1 {
              if data[i] == decompressed[i] {
                match_count = match_count + 1
              }
            }
            if match_count == data.length() {
              println("✓ 大小" + size.to_string() + ": 完全匹配")
            } else {
              println("✗ 大小" + size.to_string() + ": 仅" + match_count.to_string() + "/" + data.length().to_string() + "匹配")
              abort("内容不匹配")
            }
          }
          @username/moonbit_fse/src.CompressionResult::Error(msg) => {
            println("✗ 大小" + size.to_string() + ": 解压缩失败 - " + msg)
            abort("解压缩失败")
          }
          _ => {
            println("✗ 大小" + size.to_string() + ": 解压缩返回意外结果")
            abort("解压缩失败")
          }
        }
      }
      @username/moonbit_fse/src.CompressionResult::NotCompressible => {
        println("  大小" + size.to_string() + ": 不可压缩（跳过）")
      }
      _ => {
        println("✗ 大小" + size.to_string() + ": 压缩失败")
        abort("压缩失败")
      }
    }
  }
  
  println("所有测试通过！")
}

