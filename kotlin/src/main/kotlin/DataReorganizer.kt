import java.io.File
import java.util.Scanner

fun dataReorganize(directory: File) {
    if(!directory.exists()) return

    var rx = 6
    var tx = 6
    var range = 128
    var velocity = 96
    val data = mutableListOf<List<String>>()

    directory.listFiles()?.filter { it.extension == "dv" }?.forEach { file ->
        val scanner = Scanner(file)

    }
}