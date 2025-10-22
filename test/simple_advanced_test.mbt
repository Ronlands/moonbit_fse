/// 简单高级压缩功能测试

test "simple_advanced_fse_test" {
  // 测试数据
  let test_data: Array[Byte] = []
  for i = 0; i < 50; i = i + 1 {
    test_data.push((i % 8).to_byte())  // 重复模式
  }
  let data = Bytes::from_array(test_data)
  
  let fse_options = @username/moonbit_fse/src.create_default_fse_options()
  let fse_result = @username/moonbit_fse/src.fse_compress_advanced(data, fse_options)
  
  match fse_result {
    @username/moonbit_fse/src.CompressionResult::Success(compressed) => {
      // 验证压缩成功
      let decompressed = @username/moonbit_fse/src.fse_decompress_advanced(compressed)
      match decompressed {
        @username/moonbit_fse/src.CompressionResult::Success(decompressed_data) => {
          if decompressed_data.length() != data.length() {
            abort("FSE解压缩长度不匹配")
          }
        }
        _ => abort("FSE解压缩失败")
      }
    }
    @username/moonbit_fse/src.CompressionResult::NotCompressible => ()  // 数据不可压缩是正常的
    _ => abort("FSE压缩失败")
  }
}

test "simple_advanced_rle_test" {
  // 测试RLE
  let test_data: Array[Byte] = []
  for i = 0; i < 80; i = i + 1 {
    test_data.push(77)  // 全部是'M'
  }
  let data = Bytes::from_array(test_data)
  
  let fse_options = @username/moonbit_fse/src.create_default_fse_options()
  let fse_result = @username/moonbit_fse/src.fse_compress_advanced(data, fse_options)
  
  match fse_result {
    @username/moonbit_fse/src.CompressionResult::SingleSymbol(compressed) => {
      // 验证RLE压缩效果
      if compressed.length() >= 10 {  // RLE应该非常小
        println("Warning: RLE压缩大小 = " + compressed.length().to_string())
      }
      
      // 测试解压缩
      let decompressed = @username/moonbit_fse/src.fse_decompress_advanced(compressed)
      match decompressed {
        @username/moonbit_fse/src.CompressionResult::Success(decompressed_data) => {
          if decompressed_data.length() != data.length() {
            abort("RLE解压缩长度不匹配")
          }
        }
        _ => abort("RLE解压缩失败")
      }
    }
    _ => abort("单符号数据应该使用RLE压缩")
  }
}

test "simple_advanced_smart_test" {
  // 测试智能压缩
  let test_data: Array[Byte] = []
  for i = 0; i < 40; i = i + 1 {
    test_data.push((i % 4).to_byte())  // 重复模式
  }
  let data = Bytes::from_array(test_data)
  
  let (result, _compression_method) = @username/moonbit_fse/src.smart_compress_advanced(data)
  
  match result {
    @username/moonbit_fse/src.CompressionResult::Success(compressed) => {
      let decompressed = @username/moonbit_fse/src.smart_decompress_advanced(compressed)
      match decompressed {
        @username/moonbit_fse/src.CompressionResult::Success(decompressed_data) => {
          if decompressed_data.length() != data.length() {
            abort("智能解压缩长度不匹配")
          }
        }
        _ => abort("智能解压缩失败")
      }
    }
    @username/moonbit_fse/src.CompressionResult::NotCompressible => ()  // 数据不可压缩是正常的
    _ => abort("智能压缩失败")
  }
}
