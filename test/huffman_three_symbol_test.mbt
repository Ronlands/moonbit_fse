///|
/// 专门测试3符号的Huffman编码
test "three_symbols_detailed" {
  println("=== 详细测试3符号Huffman编码 ===")

  // 创建测试数据：0,1,2 按不同频率
  let test_data : Array[Byte] = []

  // 符号0: 20次
  for i = 0; i < 20; i = i + 1 {
    test_data.push(0)
  }

  // 符号1: 10次
  for i = 0; i < 10; i = i + 1 {
    test_data.push(1)
  }

  // 符号2: 5次
  for i = 0; i < 5; i = i + 1 {
    test_data.push(2)
  }
  let data = Bytes::from_array(test_data)
  println("数据长度: " + data.length().to_string())
  println("符号分布: 0出现20次, 1出现10次, 2出现5次")

  // 手动统计验证
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
    "验证计数: 0=" +
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
      println(
        "  压缩比: " +
        (compressed.length().to_double() / data.length().to_double()).to_string(),
      )

      // 解析头部
      println("\n头部信息:")
      println("  标记: 0x" + compressed[0].to_int().to_string())
      let max_sym = compressed[1].to_int()
      println("  max_symbol: " + max_sym.to_string())
      let orig_length = (compressed[2].to_int() << 24) |
        (compressed[3].to_int() << 16) |
        (compressed[4].to_int() << 8) |
        compressed[5].to_int()
      println("  原始长度: " + orig_length.to_string())

      // 读取所有码长
      println("\n码长:")
      for i = 0; i <= max_sym; i = i + 1 {
        if 6 + i < compressed.length() {
          println(
            "  符号" +
            i.to_string() +
            ": " +
            compressed[6 + i].to_int().to_string() +
            "位",
          )
        }
      }
      if max_sym < 2 {
        println(
          "\n⚠️  警告: max_symbol=" +
          max_sym.to_string() +
          " 但数据包含符号0,1,2",
        )
        println("    这意味着符号2丢失了！")
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

            // 验证内容
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
            println("✗ 长度不匹配")
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
      println("数据不可压缩")
      abort("不应该不可压缩")
    }
    _ => {
      println("✗ 压缩失败")
      abort("压缩失败")
    }
  }
}

