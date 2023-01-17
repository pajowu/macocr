import ArgumentParser
@available(macOS 11.0, *)
@main
struct MacOCR: ArgumentParser.ParsableCommand {
    @Flag(inversion: FlagInversion.prefixedNo, help: "fast")
    var fast = false
    
    
    @Option(name: .shortAndLong, help: "User word file")
    var wordfile: String?
    
    @Option(name: .shortAndLong, help: "Language Code of the languages for OCR. Can be speficied multiple times, not setting a language disables the NLP-Based LanguageCorrection")
    var language: [String] = []
    
    @Argument(completion: .file(extensions: ["pdf"]))
    var file: String
    
    @Argument()
    var out_path: String
    
    mutating func run() throws {
        print("\(language)")
        Runner.run( file: file, out_path: out_path, wordfile: wordfile, languages: language)
        
    }
}
