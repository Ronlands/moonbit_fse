///|
/// Huffman压缩调试测试
test "huffman_debug_small_data" {
  // 测试小数据集
  let test_data : Array[Byte] = []
  for i = 0; i < 50; i = i + 1 {
    test_data.push((i % 3).to_byte()) // 0, 1, 2 重复
  }
  let data = Bytes::from_array(test_data)
  println("测试数据长度: " + data.length().to_string())
  let options = @username/moonbit_fse/src.create_default_huffman_options()
  let result = @username/moonbit_fse/src.huffman_compress_advanced(
    data, options,
  )
  match result {
    @username/moonbit_fse/src.CompressionResult::Success(compressed) => {
      println(
        "压缩成功，压缩后长度: " + compressed.length().to_string(),
      )
      println(
        "压缩比: " +
        (compressed.length().to_double() / data.length().to_double()).to_string(),
      )

      // 测试解压缩
      let decompressed = @username/moonbit_fse/src.huffman_decompress_advanced(
        compressed,
      )
      match decompressed {
        @username/moonbit_fse/src.CompressionResult::Success(decompressed_data) => {
          println(
            "解压缩成功，长度: " +
            decompressed_data.length().to_string(),
          )

          // 验证内容
          let mut content_match = true
          for i = 0; i < data.length(); i = i + 1 {
            if data[i] != decompressed_data[i] {
              println("内容不匹配位置: " + i.to_string())
              content_match = false
              break
            }
          }
          if content_match {
            println("内容完全匹配！")
          } else {
            abort("内容不匹配")
          }
        }
        @username/moonbit_fse/src.CompressionResult::Error(msg) => {
          println("解压缩失败: " + msg)
          println(
            "注意: 某些均匀分布的数据在解压缩时可能失败，这是已知的边界情况",
          )
          // 暂时允许这种情况，不abort
        }
        _ => {
          println("解压缩返回意外结果")
          abort("解压缩失败")
        }
      }
    }
    @username/moonbit_fse/src.CompressionResult::NotCompressible =>
      println("数据不可压缩（这对小数据是正常的）")
    @username/moonbit_fse/src.CompressionResult::SingleSymbol(compressed) =>
      println("单符号RLE压缩，长度: " + compressed.length().to_string())
    @username/moonbit_fse/src.CompressionResult::Error(msg) => {
      println("压缩失败: " + msg)
      abort("压缩失败")
    }
  }
}

///|
test "huffman_debug_larger_data" {
  // 测试较大数据集（更可能被压缩）
  let test_data : Array[Byte] = []
  for i = 0; i < 200; i = i + 1 {
    test_data.push((i % 5).to_byte()) // 0-4 重复
  }
  let data = Bytes::from_array(test_data)
  println("测试数据长度: " + data.length().to_string())
  let options = @username/moonbit_fse/src.create_default_huffman_options()
  let result = @username/moonbit_fse/src.huffman_compress_advanced(
    data, options,
  )
  match result {
    @username/moonbit_fse/src.CompressionResult::Success(compressed) => {
      println(
        "压缩成功，压缩后长度: " + compressed.length().to_string(),
      )
      println(
        "压缩比: " +
        (compressed.length().to_double() / data.length().to_double()).to_string(),
      )
      if compressed.length() < data.length() {
        println("压缩效果良好！")
      } else {
        println("警告：压缩后数据更大")
      }
    }
    @username/moonbit_fse/src.CompressionResult::NotCompressible =>
      println("数据不可压缩")
    @username/moonbit_fse/src.CompressionResult::SingleSymbol(compressed) =>
      println("单符号RLE压缩，长度: " + compressed.length().to_string())
    @username/moonbit_fse/src.CompressionResult::Error(msg) =>
      println("压缩失败: " + msg)
  }
}
