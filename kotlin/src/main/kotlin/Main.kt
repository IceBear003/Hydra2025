import java.io.File
import java.util.*
import kotlin.collections.List
import kotlin.math.*

fun main(args: Array<String>) {
    val directory = File("D:\\大学\\大二下\\集创赛\\rawdata")
    for(i in 1..10) {
        val frame = File("$directory\\frame$i", "slow_time_bitdc_out.dv")

        val matrices = mutableListOf<MutableList<Double>>()
        val combined = mutableListOf<Double>()

        val theta = listOf(0.0, 0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5)
        theta.forEachIndexed { index, angleSin ->
            val outputFile = File("$directory\\frame$i", "combined_origin.txt")
            val scanner = Scanner(frame)
            repeat(6 * 6) { channel ->
                val tx = channel / 6
                val rx = channel % 6
                val lambda = 4 * tx + rx
                val weight = lambda * angleSin * -0.5 * PI * 0.25
                print(cos(weight))
                print(" ")
                println(sin(weight))
                val weightRe = 1 * cos(weight)
                val weightIm = 1 * sin(weight)

                val matrix = mutableListOf<Double>()
                repeat(128) { range ->
                    repeat(96) repeat_96@{ velocity ->
//                        if (channel / 6 != 0)
//                            return@repeat_96
                        val hex = scanner.nextLine()
                        val binary = hex.substring(2).hexToBinary().padStart(32, '0')
                        var imPart = binary.substring(0, 14).binaryToSignedInt(14)
                        var rePart = binary.substring(14, 28).binaryToSignedInt(14)

                        imPart = (imPart * weightRe + rePart * weightIm).toInt()
                        rePart = (rePart * weightRe - imPart * weightIm).toInt()

                        val expPart = binary.substring(28).binaryToSignedInt(4)

                        val mag = getMag(imPart, rePart) * 2.0.pow(expPart)

                        if (channel == 0) {
                            combined += mag * mag;
                        } else {
                            combined[range * 96 + velocity] += mag * mag
                        }
                    }
                }
                matrices += matrix
            }

            val combinedDB = combined.map { String.format("%.2f", log10(it) * 10) }

            outputFile.delete()
            outputFile.printWriter().use {
                repeat(128) { i ->
                    repeat(96) { j -> it.print(" " + combinedDB[i * 96 + j]) }
                    it.print("\n")
                }
            }
        }
    }
}

fun getMag(im: Int, re: Int): Int = (abs(im) to abs(re)).let { (a, b) -> max(a, b) + min(a, b) / 4 }

fun String.hexToBinary() : String = Integer.toBinaryString(Integer.parseUnsignedInt(this, 16))

fun String.binaryToSignedInt(width: Int) : Int {
    val abs = substring(1).let { Integer.parseUnsignedInt(it, 2) }
    return if(this[0] == '0') abs else (abs - (1 shl (width - 1)))
}