//
//  google-fonts-families.swift — for each index line, the family CoreText reads from the
//  family's first font file (see google-fonts-index.py).
//
import CoreText
import Foundation
// For each index line: the family name CoreText reads from the family's first font file.
let root = CommandLine.arguments[1], index = CommandLine.arguments[2]
for line in try! String(contentsOfFile: index, encoding: .utf8).split(separator: "\n") {
    let f = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
    let first = f[5].split(separator: ";")[0].split(separator: ":")[0]
    let url = URL(fileURLWithPath: "\(root)/\(f[2])/\(f[1])/\(first)")
    let ds = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor] ?? []
    let fams = Set(ds.compactMap { CTFontDescriptorCopyAttribute($0, kCTFontFamilyNameAttribute) as? String })
    print("\(f[1])\t\(fams.sorted().joined(separator: "|"))")
}
