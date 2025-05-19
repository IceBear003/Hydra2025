import java.io.File
import java.util.*

fun main(args: Array<String>) {
    val scanner = Scanner(System.`in`)
    print("Please input the path of the source folder: ")
    val srcDirectory = File(scanner.nextLine().replace("\\","/"))
    print("Please input the path of the dest folder: ")
    val destDirectory = File(scanner.nextLine().replace("\\","/"))
    dataReorganize(srcDirectory, destDirectory)
    print("Conversion done.")
}