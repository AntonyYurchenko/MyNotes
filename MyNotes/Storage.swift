//
//  Storage.swift
//  MyNotes
//
//  Created by Antony Yurchenko on 1/30/17.
//  Copyright © 2017 antonybrro. All rights reserved.
//

import Foundation

protocol Storage {
    func load() -> [Note]
    func add(index : Int, note : Note)
    func update(index : Int, note : Note)
    func delete(index : Int)
}
