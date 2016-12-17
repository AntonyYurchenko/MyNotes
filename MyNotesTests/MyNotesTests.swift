//
//  MyNotesTests.swift
//  MyNotesTests
//
//  Created by Antony Yurchenko on 15/12/16.
//  Copyright © 2016 antonybrro. All rights reserved.
//

import XCTest
@testable import MyNotes

class MyNotesTests: XCTestCase {
    
    func textNoteSucceeds() {
        let normalNote = Note.init(title: "Title", note: "Note", date: "Date")
        XCTAssertNotNil(normalNote)
    }
    
}
