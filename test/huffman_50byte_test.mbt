///|
/// 测试50字节的3符号情况
test "fifty_bytes_three_symbols" {
  println("=== 测试50字节3符号（循环模式） ===")

  // 创建测试数据：0,1,2 循环
  let test_data : Array[Byte] = []
  for i = 0; i < 50; i = i + 1 {
    test_data.push((i % 3).to_byte())
  }
  let data = Bytes::from_array(test_data)
  println("数据长度: " + data.length().to_string())

  // 统计符号
  let mut count0 = 0
  let mut count1 = 0
  let mut count2 = 0
  for i = 0; i < data.length(); i = i + 1 {
    match data[i].to_int() {
      0 => count0 = count0 + 1
      1 => count1 = count1 + 1
      2 => count2 = count2 + 1
      _ => ()
    }
  }
  println(
    "符号分布: 0=" +
    count0.to_string() +
    ", 1=" +
    count1.to_string() +
    ", 2=" +
    count2.to_string(),
  )

  // 压缩
  let options = @username/moonbit_fse/src.create_default_huffman_options()
  let result = @username/moonbit_fse/src.huffman_compress_advanced(
    data, options,
  )
  match result {
    @username/moonbit_fse/src.CompressionResult::Success(compressed) => {
      println("\n✓ 压缩成功")
      println("  压缩后长度: " + compressed.length().to_string())

      // 解析头部
      let max_sym = compressed[1].to_int()
      println("  max_symbol: " + max_sym.to_string())
      println("\n码长（max_symbol=" + max_sym.to_string() + "）:")
      for i = 0; i <= max_sym; i = i + 1 {
        if 6 + i < compressed.length() {
          println(
            "  符号" +
            i.to_string() +
            ": " +
            compressed[6 + i].to_int().to_string() +
            "位",
          )
        } else {
          println("  符号" + i.to_string() + ": 索引超出范围！")
        }
      }
      let expected_header_size = 6 + max_sym + 1
      println("\n期望头部大小: " + expected_header_size.to_string())
      println("实际压缩数据长度: " + compressed.length().to_string())
      if compressed.length() < expected_header_size {
        println(
          "⚠️  警告：压缩数据太短，无法包含完整头部！",
        )
      }

      // 尝试解压缩
      println("\n开始解压缩...")
      let decompressed_result = @username/moonbit_fse/src.huffman_decompress_advanced(
        compressed,
      )
      match decompressed_result {
        @username/moonbit_fse/src.CompressionResult::Success(decompressed) => {
          println("✓ 解压缩成功")
          println("  解压缩长度: " + decompressed.length().to_string())
          if decompressed.length() == data.length() {
            println("✓ 长度匹配")

            // 详细验证内容
            let mut errors = 0
            for i = 0; i < data.length(); i = i + 1 {
              if data[i] != decompressed[i] {
                if errors < 10 {
                  println(
                    "  ✗ 位置" +
                    i.to_string() +
                    ": 期望" +
                    data[i].to_int().to_string() +
                    ", 实际" +
                    decompressed[i].to_int().to_string(),
                  )
                }
                errors = errors + 1
              }
            }
            if errors > 0 {
              println("✗ 总共" + errors.to_string() + "个错误")
              abort("内容不匹配")
            } else {
              println("✓ 所有内容匹配！")
            }
          } else {
            println(
              "✗ 长度不匹配: 期望" +
              data.length().to_string() +
              ", 实际" +
              decompressed.length().to_string(),
            )
            abort("长度不匹配")
          }
        }
        @username/moonbit_fse/src.CompressionResult::Error(msg) => {
          println("✗ 解压缩失败: " + msg)
          abort("解压缩失败")
        }
        _ => {
          println("✗ 解压缩返回意外结果")
          abort("解压缩失败")
        }
      }
    }
    @username/moonbit_fse/src.CompressionResult::NotCompressible =>
      println("数据不可压缩")
    // 对于均匀分布的数据，这是可能的
    _ => {
      println("✗ 压缩失败")
      abort("压缩失败")
    }
  }
}
