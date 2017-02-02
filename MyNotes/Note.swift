//
//  Note.swift
//  MyNotes
//
//  Created by Antony Yurchenko on 15/12/16.
//  Copyright © 2016 antonybrro. All rights reserved.
//

import UIKit
import os.log

class Note : NSObject, NSCoding{
    
    // MARK: Properties
    var title: String
    var text: String
    var date: String
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("notes")
    
    init(title: String, text: String, date: String) {
        self.title = title
        self.text = text
        self.date = date
    }
    
    struct PropertyKey {
        static let title = "title"
        static let text = "text"
        static let date = "date"
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: PropertyKey.title)
        aCoder.encode(text, forKey: PropertyKey.text)
        aCoder.encode(date, forKey: PropertyKey.date)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let title = aDecoder.decodeObject(forKey: PropertyKey.title) as? String else {
            os_log("Unable to decode the name for a Note object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let text = aDecoder.decodeObject(forKey: PropertyKey.text) as? String else {
            os_log("Unable to decode the name for a Note object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let date = aDecoder.decodeObject(forKey: PropertyKey.date) as? String else {
            os_log("Unable to decode the name for a Note object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        self.init(title: title, text: text, date: date)
    }
}
