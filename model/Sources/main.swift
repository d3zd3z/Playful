// Experiment with the steno engine, separate from the GUI.

import SQLite
import Foundation

print("Initializing lesson\n")

// var lesson = Lesson(dictPath: "../Playful/dict-canonical.json",
//    lessonPath: "../Playful/lessons.json")

if !FileManager.default.fileExists(atPath: "status.sqlite3") {
    let db = try Connection("status.sqlite3")
    try Lesson.create(db: db, dictPath: "../Playful/dict-canonical.json",
        lessonPath: "../Playful/lessons.json")
}

let db = try Connection("status.sqlite3")
db.trace { SQL in print(SQL) }
var lesson = Lesson(db: db)
while let word = try lesson.getNext() {
    print("Learn \(word.english) is \(word.strokes) (1, don't know, 4 know fully)")
    if let resp = readLine() {
        try word.update(level: Int(resp)! - 1)
    } else {
        break
    }
}

/*
let words = Table("words")
let strokes = Expression<String>("strokes")
let duration = Expression<Float64>("duration")

try db.run(words.create { t in
   t.column(strokes, primaryKey: true)
   t.column(duration)
})
*/
