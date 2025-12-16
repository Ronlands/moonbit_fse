///|
/// 调试Huffman编码解码表
test "debug_encode_decode_table" {
  println("=== 测试编码/解码表一致性 ===")

  // 使用与50字节测试相同的分布创建数据
  let test_data : Array[Byte] = []
  for i = 0; i < 50; i = i + 1 {
    test_data.push((i % 3).to_byte())
  }
  let data = Bytes::from_array(test_data)
  println("测试数据：50字节，符号0,1,2循环")
  println(
    "前10个字节: " +
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
    data[9].to_int().to_string(),
  )

  // 压缩
  let options = @username/moonbit_fse/src.create_default_huffman_options()
  let result = @username/moonbit_fse/src.huffman_compress_advanced(
    data, options,
  )
  match result {
    @username/moonbit_fse/src.CompressionResult::Success(compressed) => {
      println(
        "\n✓ 压缩成功，压缩后长度: " +
        compressed.length().to_string(),
      )

      // 解压缩
      let decompressed_result = @username/moonbit_fse/src.huffman_decompress_advanced(
        compressed,
      )
      match decompressed_result {
        @username/moonbit_fse/src.CompressionResult::Success(decompressed) => {
          println(
            "✓ 解压缩成功，解压缩后长度: " +
            decompressed.length().to_string(),
          )
          println(
            "\n前10个解压缩字节: " +
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
            decompressed[9].to_int().to_string(),
          )

          // 详细对比
          println("\n详细对比前20个字节:")
          for i = 0; i < 20 && i < data.length(); i = i + 1 {
            if data[i] == decompressed[i] {
              println(
                "  位置" +
                i.to_string() +
                ": " +
                data[i].to_int().to_string() +
                " ✓",
              )
            } else {
              println(
                "  位置" +
                i.to_string() +
                ": 期望" +
                data[i].to_int().to_string() +
                ", 实际" +
                decompressed[i].to_int().to_string() +
                " ✗",
              )
            }
          }
        }
        @username/moonbit_fse/src.CompressionResult::Error(msg) => {
          println("✗ 解压缩失败: " + msg)

          // 尝试手动解析来调试
          println("\n手动解析压缩数据:")
          println("  标记: 0x" + compressed[0].to_int().to_string())
          println("  max_symbol: " + compressed[1].to_int().to_string())
          let orig_len = (compressed[2].to_int() << 24) |
            (compressed[3].to_int() << 16) |
            (compressed[4].to_int() << 8) |
            compressed[5].to_int()
          println("  原始长度: " + orig_len.to_string())
          let max_sym = compressed[1].to_int()
          println("\n  码长:")
          for i = 0; i <= max_sym; i = i + 1 {
            println(
              "    符号" +
              i.to_string() +
              ": " +
              compressed[6 + i].to_int().to_string() +
              "位",
            )
          }
          let header_size = 6 + max_sym + 1
          let data_size = compressed.length() - header_size
          println("\n  头部大小: " + header_size.to_string())
          println("  压缩数据大小: " + data_size.to_string())
          println("  压缩数据起始位置: " + header_size.to_string())
          if data_size > 0 {
            println("\n  前几个压缩数据字节:")
            let mut bytes_str = "    "
            for i = 0; i < 8 && header_size + i < compressed.length(); i = i + 1 {
              bytes_str = bytes_str +
                compressed[header_size + i].to_int().to_string() +
                " "
            }
            println(bytes_str)
          }
          abort("解压缩失败")
        }
        _ => {
          println("✗ 解压缩返回意外结果")
          abort("解压缩失败")
        }
      }
    }
    _ => {
      println("✗ 压缩失败")
      abort("压缩失败")
    }
  }
}

