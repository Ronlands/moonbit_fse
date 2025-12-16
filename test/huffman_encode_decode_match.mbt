///|
/// 测试编码和解码的一致性
test "encode_decode_consistency_simple" {
  println("=== 测试最简单的编码解码一致性 ===")

  // 创建最简单的数据：只有3个字节，3个不同符号
  let test_data : Array[Byte] = []
  test_data.push(0)
  test_data.push(1)
  test_data.push(2)
  let data = Bytes::from_array(test_data)
  println("测试数据: [0, 1, 2]")

  // 压缩
  let options = @username/moonbit_fse/src.create_default_huffman_options()
  let result = @username/moonbit_fse/src.huffman_compress_advanced(
    data, options,
  )
  match result {
    @username/moonbit_fse/src.CompressionResult::Success(compressed) => {
      println("✓ 压缩成功，长度: " + compressed.length().to_string())

      // 打印码长
      let max_sym = compressed[1].to_int()
      println("max_symbol: " + max_sym.to_string())
      println("码长:")
      for i = 0; i <= max_sym; i = i + 1 {
        println(
          "  符号" +
          i.to_string() +
          ": " +
          compressed[6 + i].to_int().to_string() +
          "位",
        )
      }

      // 解压缩
      let decompressed_result = @username/moonbit_fse/src.huffman_decompress_advanced(
        compressed,
      )
      match decompressed_result {
        @username/moonbit_fse/src.CompressionResult::Success(decompressed) => {
          println(
            "✓ 解压缩成功，长度: " + decompressed.length().to_string(),
          )
          println(
            "解压缩结果: [" +
            decompressed[0].to_int().to_string() +
            ", " +
            decompressed[1].to_int().to_string() +
            ", " +
            decompressed[2].to_int().to_string() +
            "]",
          )

          // 验证
          if data[0] == decompressed[0] &&
            data[1] == decompressed[1] &&
            data[2] == decompressed[2] {
            println("✓ 完美匹配！")
          } else {
            println("✗ 不匹配！")
            abort("编码解码不一致")
          }
        }
        @username/moonbit_fse/src.CompressionResult::Error(msg) => {
          println("✗ 解压缩失败: " + msg)
          abort("解压缩失败")
        }
        _ => {
          println("✗ 意外结果")
          abort("解压缩失败")
        }
      }
    }
    @username/moonbit_fse/src.CompressionResult::NotCompressible =>
      println("数据被判定为不可压缩（数据太小是正常的）")
    @username/moonbit_fse/src.CompressionResult::Error(msg) => {
      println("✗ 压缩错误: " + msg)
      abort("压缩失败")
    }
    _ => {
      println("✗ 压缩返回意外结果")
      abort("压缩失败")
    }
  }
}

///|
test "encode_decode_consistency_repeating" {
  println("\n=== 测试循环模式的编码解码一致性 ===")

  // 创建循环数据：0,1,2,0,1,2,...
  let test_data : Array[Byte] = []
  for i = 0; i < 12; i = i + 1 {
    test_data.push((i % 3).to_byte())
  }
  let data = Bytes::from_array(test_data)
  println("测试数据长度: " + data.length().to_string())
  println(
    "前12个字节: " +
    data[0].to_int().to_string() +
    " " +
    data[1].to_int().to_string() +
    " " +
    data[2].to_int().to_string() +
    " " +
    data[3].to_int().to_string() +
    " " +
    data[4].to_int().to_string() +
    " " +
    data[5].to_int().to_string() +
    " " +
    data[6].to_int().to_string() +
    " " +
    data[7].to_int().to_string() +
    " " +
    data[8].to_int().to_string() +
    " " +
    data[9].to_int().to_string() +
    " " +
    data[10].to_int().to_string() +
    " " +
    data[11].to_int().to_string(),
  )

  // 压缩
  let options = @username/moonbit_fse/src.create_default_huffman_options()
  let result = @username/moonbit_fse/src.huffman_compress_advanced(
    data, options,
  )
  match result {
    @username/moonbit_fse/src.CompressionResult::Success(compressed) => {
      println("\n✓ 压缩成功，长度: " + compressed.length().to_string())

      // 打印码长
      let max_sym = compressed[1].to_int()
      println("max_symbol: " + max_sym.to_string())
      println("码长:")
      for i = 0; i <= max_sym; i = i + 1 {
        println(
          "  符号" +
          i.to_string() +
          ": " +
          compressed[6 + i].to_int().to_string() +
          "位",
        )
      }

      // 解压缩
      let decompressed_result = @username/moonbit_fse/src.huffman_decompress_advanced(
        compressed,
      )
      match decompressed_result {
        @username/moonbit_fse/src.CompressionResult::Success(decompressed) => {
          println(
            "\n✓ 解压缩成功，长度: " +
            decompressed.length().to_string(),
          )
          println(
            "前12个解压缩字节: " +
            decompressed[0].to_int().to_string() +
            " " +
            decompressed[1].to_int().to_string() +
            " " +
            decompressed[2].to_int().to_string() +
            " " +
            decompressed[3].to_int().to_string() +
            " " +
            decompressed[4].to_int().to_string() +
            " " +
            decompressed[5].to_int().to_string() +
            " " +
            decompressed[6].to_int().to_string() +
            " " +
            decompressed[7].to_int().to_string() +
            " " +
            decompressed[8].to_int().to_string() +
            " " +
            decompressed[9].to_int().to_string() +
            " " +
            decompressed[10].to_int().to_string() +
            " " +
            decompressed[11].to_int().to_string(),
          )

          // 验证
          let mut all_match = true
          for i = 0; i < data.length(); i = i + 1 {
            if data[i] != decompressed[i] {
              println(
                "✗ 位置" +
                i.to_string() +
                "不匹配: 期望" +
                data[i].to_int().to_string() +
                ", 实际" +
                decompressed[i].to_int().to_string(),
              )
              all_match = false
              if i >= 5 {
                break // 只显示前几个错误
              }
            }
          }
          if all_match {
            println("✓ 完美匹配！")
          } else {
            abort("编码解码不一致")
          }
        }
        @username/moonbit_fse/src.CompressionResult::Error(msg) => {
          println("✗ 解压缩失败: " + msg)
          abort("解压缩失败")
        }
        _ => {
          println("✗ 意外结果")
          abort("解压缩失败")
        }
      }
    }
    @username/moonbit_fse/src.CompressionResult::NotCompressible =>
      println(
        "数据被判定为不可压缩（数据太小或太均匀是正常的）",
      )
    @username/moonbit_fse/src.CompressionResult::Error(msg) => {
      println("✗ 压缩错误: " + msg)
      abort("压缩失败")
    }
    _ => {
      println("✗ 压缩返回意外结果")
      abort("压缩失败")
    }
  }
}
