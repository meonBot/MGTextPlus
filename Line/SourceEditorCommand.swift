//
//  SourceEditorCommand.swift
//  Line
//
//  Created by Tuan Truong on 11/5/16.
//  Copyright © 2016 Tuan Truong. All rights reserved.
//

import Foundation
import XcodeKit
import AppKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        guard let textRange = invocation.buffer.selections.firstObject as? XCSourceTextRange,
            invocation.buffer.lines.count > 0 else {
                completionHandler(nil)
                return
        }
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            completionHandler(nil)
            return
        }
        
        let deleteLineIdentifier = bundleIdentifier + ".DeleteLine"
        let duplicateLineIdentifier = bundleIdentifier + ".DuplicateLine"
        let copyLineIdentifier = bundleIdentifier + ".CopyLine"
        let cutLineIdentifier = bundleIdentifier + ".CutLine"
        let joinLinesIdentifier = bundleIdentifier + ".JoinLines"
        
        let targetRange = Range(uncheckedBounds: (lower: textRange.start.line, upper: min(textRange.end.line + 1, invocation.buffer.lines.count)))
        let indexSet = IndexSet(integersIn: targetRange)
        let selectedLines = invocation.buffer.lines.objects(at: indexSet)
        
        func deleteLines(indexSet: IndexSet) {
            invocation.buffer.lines.removeObjects(at: indexSet)
            let lineSelection = XCSourceTextRange()
            lineSelection.start = XCSourceTextPosition(line: targetRange.lowerBound, column: 0)
            lineSelection.end = XCSourceTextPosition(line: targetRange.lowerBound, column: 0)
            invocation.buffer.selections.setArray([lineSelection])
        }
        
        func copyLines() {
            var copyLines = [String]()
            for line in selectedLines {
                copyLines.append(line as! String)
            }
            let newString = copyLines.joined()
            let pasteboard = NSPasteboard.general()
            pasteboard.declareTypes([NSPasteboardTypeString], owner: nil)
            pasteboard.setString(newString, forType: NSPasteboardTypeString)
        }
        
        // Switch all different commands id based which defined in Info.plist
        switch invocation.commandIdentifier {
        case deleteLineIdentifier:
            deleteLines(indexSet: indexSet)
        case duplicateLineIdentifier:
            let lineSelection = XCSourceTextRange()
            lineSelection.start = XCSourceTextPosition(line: textRange.start.line + targetRange.count, column: textRange.start.column)
            lineSelection.end = XCSourceTextPosition(line: textRange.end.line + targetRange.count, column: textRange.end.column)
            invocation.buffer.lines.insert(selectedLines, at: indexSet)
            invocation.buffer.selections.setArray([lineSelection])
        case copyLineIdentifier:
            copyLines()
        case cutLineIdentifier:
            copyLines()
            deleteLines(indexSet: indexSet)
        case joinLinesIdentifier:
            let newLine: String
            if indexSet.count == 1 {
                let currentRow = indexSet.last!
                guard currentRow < invocation.buffer.lines.count - 1 else {
                    break
                }
                let firstLine = invocation.buffer.lines[currentRow] as! String
                let secondLine = invocation.buffer.lines[currentRow + 1] as! String
                newLine = firstLine.trimEnd() + " " + secondLine.trimStart()
                invocation.buffer.lines[currentRow] = newLine
                invocation.buffer.lines.removeObject(at: currentRow + 1)
                
                let lineSelection = XCSourceTextRange()
                lineSelection.start = XCSourceTextPosition(line: textRange.start.line, column: firstLine.characters.count)
                if textRange.start.column == textRange.end.column {
                    lineSelection.end = lineSelection.start
                    invocation.buffer.selections.setArray([lineSelection])
                }
                else {
               
                }
                
            }
            else {
                var lines = [String]()
                for (index, line) in selectedLines.enumerated() {
                    let line = line as! String
                    if index == 0 {
                        lines.append(line.trimEnd())
                    }
                    else if index == selectedLines.count - 1 {
                        lines.append(line.trimStart())
                    }
                    else {
                        lines.append(line.trim())
                    }
                }
                newLine = lines.joined(separator: " ")
                invocation.buffer.lines[indexSet.first!] = newLine
                let indexSetToRemove = IndexSet(integersIn: Range(uncheckedBounds: (lower: textRange.start.line + 1, upper: min(textRange.end.line + 1, invocation.buffer.lines.count))))
                deleteLines(indexSet: indexSetToRemove)
                
                let lineSelection = XCSourceTextRange()
                lineSelection.start = XCSourceTextPosition(line: textRange.start.line, column: textRange.start.column)
                lineSelection.end = XCSourceTextPosition(line: textRange.start.line, column: newLine.characters.count - 1)
               
                invocation.buffer.selections.setArray([lineSelection])
            }
          
        default:
            break
        }
        
        completionHandler(nil)
    }
    
}
