//
//  Runner.swift
//  macocr
//
//  Created by Matthias Winkelmann on 13.01.22.
//
import Cocoa
import Vision
import Foundation



@available(macOS 11.0, *)
class Runner {
    
    
    
    static func convertPDF(at sourceURL: URL, to destinationURL: URL, languages: [String], dpi: CGFloat = 200, customWords: [String]?) throws -> [[String]] {
        
        let pdfDocument = CGPDFDocument(sourceURL as CFURL)!
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
        
        var texts = [[String]](repeating: [], count: pdfDocument.numberOfPages)
        DispatchQueue.concurrentPerform(iterations: pdfDocument.numberOfPages) { i in
            // Page number starts at 1, not 0
            let pdfPage = pdfDocument.page(at: i + 1)!
            
            let mediaBoxRect = pdfPage.getBoxRect(.mediaBox)
            let scale = dpi / 72.0
            let width = Int(mediaBoxRect.width * scale)
            let height = Int(mediaBoxRect.height * scale)
            
            let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo)!
            context.interpolationQuality = .high
            context.setFillColor(.white)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.scaleBy(x: scale, y: scale)
            context.drawPDFPage(pdfPage)
            
            let image = context.makeImage()!
            texts[i] = processImage(imgRef: image, languages: languages, customWords: customWords)
            let pageOutputFile = destinationURL.appendingPathComponent("Page\(i+1).txt")
            do {
                try texts[i].joined(separator: "\n").write(to: pageOutputFile, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("Failed to write txt-file for Page \(i+1): \(error).")
            }
            print("Finished Page \(i+1)")
        }
        return texts
    }
    
    static func processImage(imgRef: CGImage, languages: [String], customWords: [String]?) -> [String] {
        var text: [String] = [];
        let request = VNRecognizeTextRequest { (request, error) in
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            text = observations.map { $0.topCandidates(1).first?.string ?? ""}
        }
        request.recognitionLevel = VNRequestTextRecognitionLevel.accurate // or .fast
        request.revision = VNRecognizeTextRequestRevision2
        request.usesLanguageCorrection = true
        request.recognitionLanguages = languages
        if let customWords = customWords {
            request.customWords = customWords
        }
        
        try? VNImageRequestHandler(cgImage: imgRef, options: [:]).perform([request])
        return text
    }
    
    static func run(file: String, out_path: String, wordfile: String?, languages: [String]) -> Int32 {
        var customWords: [String]? = nil;
        if let wordfile = wordfile {
            do {
                let customWordList = try String(contentsOfFile: wordfile, encoding: .utf8)
                
                customWords = customWordList
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .newlines)
            } catch {
                print("Failed to read wordlist: \(error)")
            }
        }
        
        let _ = (try? convertPDF(at: URL.init(fileURLWithPath: file), to: URL.init(fileURLWithPath: out_path), languages: languages, customWords: customWords))!
        
        return 0
    }
}
