import java.io.File
import java.util.*

fun main(args: Array<String>) {
    val scanner = Scanner(System.`in`)
    print("Please input the path of the source folder: ")
//    val srcDirectory = File(scanner.nextLine().replace("\\","/"))
    val srcDirectory = File("D:\\大学\\大二下\\集创赛\\Hydra2025\\初赛提交材料\\技术数据\\数据流生成\\raw_data")
    print("Please input the path of the dest folder: ")
//    val destDirectory = File(scanner.nextLine().replace("\\","/"))
    val destDirectory = File("D:\\大学\\大二下\\集创赛\\Hydra2025\\初赛提交材料\\技术数据\\数据流生成\\converted_data")
    dataReorganize(srcDirectory, destDirectory)
    print("Conversion done.")
}