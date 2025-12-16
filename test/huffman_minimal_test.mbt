///|
/// 最小Huffman测试 - 找出具体问题
test "huffman_minimal_two_symbols" {
  // 最简单的情况：只有两个不同的符号
  let test_data : Array[Byte] = []
  // 10个0，10个1
  for i = 0; i < 10; i = i + 1 {
    test_data.push(0)
  }
  for i = 0; i < 10; i = i + 1 {
    test_data.push(1)
  }
  let data = Bytes::from_array(test_data)
  println("=== 测试2符号Huffman编码 ===")
  println("原始数据长度: " + data.length().to_string())
  println("符号: 0出现10次, 1出现10次")
  let options = @username/moonbit_fse/src.create_default_huffman_options()
  let result = @username/moonbit_fse/src.huffman_compress_advanced(
    data, options,
  )
  match result {
    @username/moonbit_fse/src.CompressionResult::Success(compressed) => {
      println("✓ 压缩成功")
      println("  压缩后长度: " + compressed.length().to_string())
      println("  头部信息:")
      println("    标记: 0x" + compressed[0].to_int().to_string())
      println("    max_symbol: " + compressed[1].to_int().to_string())

      // 尝试解压缩
      let decompressed_result = @username/moonbit_fse/src.huffman_decompress_advanced(
        compressed,
      )
      match decompressed_result {
        @username/moonbit_fse/src.CompressionResult::Success(decompressed) => {
          println("✓ 解压缩成功")
          println("  解压缩长度: " + decompressed.length().to_string())
          if decompressed.length() == data.length() {
            println("✓ 长度匹配")

            // 验证内容
            let mut errors = 0
            for i = 0; i < data.length(); i = i + 1 {
              if data[i] != decompressed[i] {
                if errors < 5 { // 只打印前5个错误
                  println(
                    "✗ 位置" +
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
            if errors == 0 {
              println("✓ 所有内容匹配！测试通过！")
            } else {
              println("✗ 发现" + errors.to_string() + "个错误")
              abort("内容不匹配")
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
    @username/moonbit_fse/src.CompressionResult::NotCompressible => {
      println("数据被判定为不可压缩")
      // 对于这么简单的数据，不应该不可压缩
      abort("不应该不可压缩")
    }
    _ => {
      println("✗ 压缩失败")
      abort("压缩失败")
    }
  }
}

///|
test "huffman_minimal_three_symbols" {
  // 稍微复杂一点：三个符号，频率不同
  let test_data : Array[Byte] = []
  // 20个0，10个1，5个2
  for i = 0; i < 20; i = i + 1 {
    test_data.push(0)
  }
  for i = 0; i < 10; i = i + 1 {
    test_data.push(1)
  }
  for i = 0; i < 5; i = i + 1 {
    test_data.push(2)
  }
  let data = Bytes::from_array(test_data)
  println("\n=== 测试3符号Huffman编码 ===")
  println("原始数据长度: " + data.length().to_string())
  println("符号: 0出现20次, 1出现10次, 2出现5次")
  let options = @username/moonbit_fse/src.create_default_huffman_options()
  let result = @username/moonbit_fse/src.huffman_compress_advanced(
    data, options,
  )
  match result {
    @username/moonbit_fse/src.CompressionResult::Success(compressed) => {
      println("✓ 压缩成功")
      println("  压缩后长度: " + compressed.length().to_string())
      println(
        "  压缩比: " +
        (compressed.length().to_double() / data.length().to_double()).to_string(),
      )
    }
    @username/moonbit_fse/src.CompressionResult::NotCompressible =>
      println("数据被判定为不可压缩")
    _ => println("✗ 压缩失败")
  }
}
