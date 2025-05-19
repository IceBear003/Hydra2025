import java.io.File
import java.nio.file.Files
import java.util.Scanner
import kotlin.io.path.absolute
import kotlin.io.path.extension
import kotlin.io.path.pathString

fun dataReorganize(srcDirectory: File, destDirectory: File) {
    if(!srcDirectory.exists()) return

    var rx: Int
    var tx: Int
    var range: Int
    var velocity: Int
    val data = mutableListOf<List<String>>()

    Files.walk(srcDirectory.toPath())?.filter { it.extension == "dv" }?.forEach { path ->
        val suffix = path.toFile().absolutePath.replace(srcDirectory.absolutePath, "")
        val outputFile = File(destDirectory.absolutePath + suffix.replace(".dv", ".txt"))
        outputFile.parentFile.mkdirs()
        outputFile.delete()
        outputFile.createNewFile()
        val printer = outputFile.printWriter()

        val scanner = Scanner(path.toFile())
        rx = scanner.nextInt()
        tx = scanner.nextInt()
        range = scanner.nextInt()
        velocity = scanner.nextInt()
        repeat(rx * tx) {
            val matrix = mutableListOf<String>()
            repeat(range * velocity) {
                val bin = Integer.toBinaryString(Integer.parseUnsignedInt(scanner.next().substring(2), 16))
                                    .padStart(32, '0')
                matrix += bin
            }
            data += matrix
        }

        val rightWindow = listOf(-3, -1, 0, 1, 2, 3, 4, 5, 7)
        val leftWindow = listOf(-2, 0, 1, 2, 3, 4, 5, 6, 8)
        var whichWindow = true
        var x= 0
        for(i in 3..<velocity step 6) {
            for(j in 0..<range) {
                repeat(rx * tx) { channel ->
                    (if(whichWindow) rightWindow else leftWindow).forEach { offset ->
                        val wrappedVelocity = if ((i + offset) >= velocity) i + offset - velocity else i + offset
                        val bin = data[channel][j * velocity + wrappedVelocity]
                        printer.printf("%s ", bin)
                    }
                    printer.println()
                }
            }
            whichWindow = !whichWindow
        }
        data.clear()
        printer.close()
    }
}