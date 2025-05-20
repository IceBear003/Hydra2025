import java.io.File
import java.util.*
import kotlin.math.*

fun generatePowerTable() {
    val directory = File("D:\\大学\\大二下\\集创赛\\Hydra2025\\kotlin\\src\\main\\resources\\raw")
    for(i in 2..2) {
        val frame = File(directory, "radar_data_channel36_range128_velocity96_target32.dv")
//        val frame = File("$directory\\frame$i", "slow_time_bitdc_out.dv")

        val matrices = mutableListOf<MutableList<Double>>()
        val combined = mutableListOf<Double>()

//        val theta = listOf(0.0, 0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5)
//        theta.forEachIndexed { index, angleSin ->
            val outputFile = File(directory, "radar_data_channel36_range128_velocity96_target32.txt")
//        val outputFile = File("$directory\\frame$i", "slow_time_bitdc_out.txt")
            val scanner = Scanner(frame)
            repeat(6 * 6) { channel ->
//                val tx = channel / 6
//                val rx = channel % 6
//                val lambda = 4 * tx + rx
//                val weight = lambda * angleSin * -0.5 * PI * 0.25
//                print(cos(weight))
//                print(" ")
//                println(sin(weight))
                val weightRe = 1 //* cos(weight)
                val weightIm = 1 //* sin(weight)

                val matrix = mutableListOf<Double>()
                repeat(128) { range ->
                    repeat(96) repeat_96@{ velocity ->
//                        if (channel / 6 != 0)
//                            return@repeat_96
                        val hex = scanner.nextLine()
                        val binary = hex.substring(2).hexToBinary().padStart(32, '0')
                        val imPart = binary.substring(0, 14).binaryToSignedInt(14) * 1.0 / 2.0.pow(13.0)
                        val rePart = binary.substring(14, 28).binaryToSignedInt(14) * 1.0 / 2.0.pow(13.0)

                        val expPart = binary.substring(28).binaryToSignedInt(4)

                        val mag = getMag(imPart, rePart) * 2.0.pow(expPart)

                        if (channel == 0) {
                            combined += mag// * mag
                        } else {
                            combined[range * 96 + velocity] += mag// * mag
                        }
                    }
                }
                matrices += matrix
            }

            val combinedDB = combined.map { String.format("%.2f", it) }

            outputFile.delete()
            outputFile.printWriter().use {
                repeat(128) { i ->
                    repeat(96) { j -> it.print(" " + combinedDB[i * 96 + j]) }
                    it.print("\n")
                }
            }
//        }
    }
}

fun getMag(im: Double, re: Double): Double = (abs(im) to abs(re)).let { (a, b) -> max(a, b) + min(a, b) / 4 }

fun String.hexToBinary() : String = Integer.toBinaryString(Integer.parseUnsignedInt(this, 16))

fun String.binaryToSignedInt(width: Int) : Int {
    val abs = substring(1).let { Integer.parseUnsignedInt(it, 2) }
    return if(this[0] == '0') abs else (abs - (1 shl (width - 1)))
}