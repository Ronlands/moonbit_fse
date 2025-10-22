/// 高级FSE和Huffman测试
/// 测试更完整的功能

test "advanced_fse_compression" {
  // 测试数据
  let test_data: Array[Byte] = []
  for i = 0; i < 100; i = i + 1 {
    test_data.push((i % 10).to_byte())  // 重复模式
  }
  let data = Bytes::from_array(test_data)
  
  let options = @username/moonbit_fse/src.create_default_fse_options()
  let result = @username/moonbit_fse/src.fse_compress_advanced(data, options)
  
  match result {
    @username/moonbit_fse/src.CompressionResult::Success(compressed) => {
      // 验证压缩成功
      if compressed.length() >= data.length() {
        abort("FSE压缩效果不佳")
      }
      
      // 测试解压缩
      let decompressed = @username/moonbit_fse/src.fse_decompress_advanced(compressed)
      match decompressed {
        @username/moonbit_fse/src.CompressionResult::Success(decompressed_data) => {
          if decompressed_data.length() != data.length() {
            abort("FSE解压缩长度不匹配")
          }
          // 验证内容
          for i = 0; i < data.length(); i = i + 1 {
            if data[i] != decompressed_data[i] {
              abort("FSE解压缩内容不匹配")
            }
          }
        }
        _ => abort("FSE解压缩失败")
      }
    }
    @username/moonbit_fse/src.CompressionResult::NotCompressible => ()  // 数据不可压缩是正常的
    _ => abort("FSE压缩失败")
  }
}

test "advanced_huffman_compression" {
  // 测试数据
  let test_data: Array[Byte] = []
  for i = 0; i < 100; i = i + 1 {
    test_data.push((i % 5).to_byte())  // 重复模式
  }
  let data = Bytes::from_array(test_data)
  
  let options = @username/moonbit_fse/src.create_default_huffman_options()
  let result = @username/moonbit_fse/src.huffman_compress_advanced(data, options)
  
  match result {
    @username/moonbit_fse/src.CompressionResult::Success(compressed) => {
      // 验证压缩成功
      if compressed.length() >= data.length() {
        abort("Huffman压缩效果不佳")
      }
      
      // 测试解压缩
      let decompressed = @username/moonbit_fse/src.huffman_decompress_advanced(compressed)
      match decompressed {
        @username/moonbit_fse/src.CompressionResult::Success(decompressed_data) => {
          if decompressed_data.length() != data.length() {
            abort("Huffman解压缩长度不匹配")
          }
          // 验证内容
          for i = 0; i < data.length(); i = i + 1 {
            if data[i] != decompressed_data[i] {
              abort("Huffman解压缩内容不匹配")
            }
          }
        }
        _ => abort("Huffman解压缩失败")
      }
    }
    @username/moonbit_fse/src.CompressionResult::NotCompressible => ()  // 数据不可压缩是正常的
    _ => abort("Huffman压缩失败")
  }
}

test "single_symbol_compression" {
  // 测试单符号数据（RLE）
  let test_data: Array[Byte] = []
  for i = 0; i < 200; i = i + 1 {
    test_data.push(65)  // 全部是'A'
  }
  let data = Bytes::from_array(test_data)
  
  let fse_options = @username/moonbit_fse/src.create_default_fse_options()
  let fse_result = @username/moonbit_fse/src.fse_compress_advanced(data, fse_options)
  
  match fse_result {
    @username/moonbit_fse/src.CompressionResult::SingleSymbol(compressed) => {
      // 验证RLE压缩效果
      if compressed.length() >= data.length() {
        abort("RLE压缩效果不佳")
      }
      
      // 测试解压缩
      let decompressed = @username/moonbit_fse/src.fse_decompress_advanced(compressed)
      match decompressed {
        @username/moonbit_fse/src.CompressionResult::Success(decompressed_data) => {
          if decompressed_data.length() != data.length() {
            abort("RLE解压缩长度不匹配")
          }
          // 验证内容
          for i = 0; i < data.length(); i = i + 1 {
            if data[i] != decompressed_data[i] {
              abort("RLE解压缩内容不匹配")
            }
          }
        }
        _ => abort("RLE解压缩失败")
      }
    }
    _ => abort("单符号数据应该使用RLE压缩")
  }
}

test "smart_compression" {
  // 测试智能压缩
  let test_data: Array[Byte] = []
  for i = 0; i < 100; i = i + 1 {
    test_data.push((i % 3).to_byte())  // 重复模式
  }
  let data = Bytes::from_array(test_data)
  
  let (result, _method) = @username/moonbit_fse/src.smart_compress_advanced(data)
  
  match result {
    @username/moonbit_fse/src.CompressionResult::Success(compressed) => {
      // 验证压缩成功
      if compressed.length() >= data.length() {
        abort("智能压缩效果不佳")
      }
      
      // 测试智能解压缩
      let decompressed = @username/moonbit_fse/src.smart_decompress_advanced(compressed)
      match decompressed {
        @username/moonbit_fse/src.CompressionResult::Success(decompressed_data) => {
          if decompressed_data.length() != data.length() {
            abort("智能解压缩长度不匹配")
          }
          // 验证内容
          for i = 0; i < data.length(); i = i + 1 {
            if data[i] != decompressed_data[i] {
              abort("智能解压缩内容不匹配")
            }
          }
        }
        _ => abort("智能解压缩失败")
      }
    }
    @username/moonbit_fse/src.CompressionResult::NotCompressible => ()  // 数据不可压缩是正常的
    _ => abort("智能压缩失败")
  }
}

test "error_handling" {
  // 测试错误处理
  let empty_data = Bytes::from_array([])
  let options = @username/moonbit_fse/src.create_default_fse_options()
  
  let result = @username/moonbit_fse/src.fse_compress_advanced(empty_data, options)
  match result {
    @username/moonbit_fse/src.CompressionResult::NotCompressible => ()  // 空数据应该返回不可压缩
    _ => abort("空数据应该返回不可压缩")
  }
  
  // 测试无效数据（跳过，因为300超出Byte范围）
  // let invalid_data: Array[Byte] = []
  // invalid_data.push(300.to_byte())  // 超出范围
}
