// Experiment with the steno engine, separate from the GUI.

import SQLite

print("Initializing lesson\n")

// var lesson = Lesson(dictPath: "../Playful/dict-canonical.json",
//    lessonPath: "../Playful/lessons.json")

let db = try Connection("status.sqlite3")
try Lesson.create(db: db, dictPath: "../Playful/dict-canonical.json",
    lessonPath: "../Playful/lessons.json")

/*
let words = Table("words")
let strokes = Expression<String>("strokes")
let duration = Expression<Float64>("duration")

try db.run(words.create { t in
   t.column(strokes, primaryKey: true)
   t.column(duration)
})
*/
