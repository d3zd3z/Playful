// A single steno lesson.

import Foundation
import SQLite

class Lesson {

    private var db: Connection
    private let words = Table("words")
    private let strokes = Expression<String>("strokes")
    private let seq = Expression<Int>("seq")
    private let english = Expression<String>("english")
    private let next = Expression<Date?>("next")
    private let interval = Expression<Float64>("interval")

    init(db: Connection) {
        self.db = db
    }

    func getNext() throws -> Word? {
        // This can be done as a single query, but it is not
        // expressible with the query language given, so just do two
        // queries.  It doesn't need to be all that fast.
        for row in try db.prepare(words // .select(strokes, words, seq, next, interval)
                .filter(next != nil)
                .filter(next < Date())
                .order(next, seq)
                .limit(1)) {
            // print("A Got row: \(row)")
            return try Word(lesson: self, row: row)
        }

        for row in try db.prepare(words // .select(strokes, words, seq, next, interval)
                .filter(next == nil)
                .order(seq)
                .limit(1)) {
            // print("B Got row: \(row)")
            return try Word(lesson: self, row: row)
        }

        return nil
    }

    func update(seq theSeq: Int, next newNext: Date, interval newInterval: Float64) throws {
        let context = words.filter(seq == theSeq)
        try db.run(context.update(next <- newNext, interval <- newInterval))
    }

    static func create(db: Connection, dictPath: String, lessonPath: String) throws {
        let problems = try loadProblems(dictPath)
        let subLessons = try loadLessons(problems, lessonPath)
        try setupDb(db: db, subLessons: subLessons)
    }

    static func loadProblems(_ dictPath: String) throws -> [Problem] {
        var problems = [Problem]()

        let url = URL(fileURLWithPath: dictPath)
        let data = try Data(contentsOf: url, options: [])
        let obj = try JSONSerialization.jsonObject(with: data, options: []) as! Dictionary<String, String>
        // print("obj: ", obj)

        for (stroke, english) in obj {
            let strokes = try Stroke.parseStrokes(stroke)
            let decoded = strokes.map({ (_ elt: Stroke) -> String in
                String(describing: elt)
            }).joined(separator: "/")
            if stroke != decoded {
                print("mismatch: \(stroke) got \(decoded)")
            }
            problems.append(Problem(strokes: strokes, english: english))
        }

        return problems
    }

    static func loadLessons(_ problems: [Problem], _ lessonPath: String) throws -> [SubLesson] {
        var subLessons = [SubLesson]()
        var workProblems = problems
        let url = URL(fileURLWithPath: lessonPath)
        let data = try Data(contentsOf: url, options: [])
        let obj = try JSONSerialization.jsonObject(with: data, options: []) as! [Dictionary<String, String>]

        for l in obj {
            let include = try Stroke.parseStroke(l["include"]!)
            let require = try Stroke.parseStroke(l["require"]!)

            var remaining = [Problem]()
            var probs = [Problem]()

            for p in workProblems {
                let p1 = p.strokes[0].value
                if (p1 & ~include.value) == 0 && (p1 & require.value) != 0 {
                    probs.append(p)
                } else {
                    remaining.append(p)
                }
            }

            workProblems = remaining

            subLessons.append(SubLesson(title: l["title"]!,
                include: include,
                require: require,
                tags: l["tags"]!,
                problems: probs))

            // print(subLessons[subLessons.count-1])
        }

        return subLessons
    }

    private static func setupDb(db: Connection, subLessons: [SubLesson]) throws {
        let lesson = Lesson(db: db)

        try db.run(lesson.words.create { t in
            t.column(lesson.strokes, primaryKey: true)
            t.column(lesson.seq, unique: true)
            t.column(lesson.english)
            t.column(lesson.next)
            t.column(lesson.interval)
        })
	try db.run(lesson.words.createIndex(lesson.next, lesson.seq))

        var s = 1
        try db.transaction {
            for sub in subLessons {
                for prob in sub.problems {
                    let text = prob.strokes.map({ (_ elt: Stroke) -> String in
                        String(describing: elt)
                    }).joined(separator: "/")
                    try db.run(lesson.words.insert(
                        lesson.strokes <- text,
                        lesson.seq <- s,
                        lesson.english <- prob.english,
                        lesson.next <- nil,
                        lesson.interval <- 15))
                    s += 1
                }
            }
        }
    }

    class Word {
        let strokes: [Stroke]
        let english: String
        let seq: Int
        let next: Date?
        let interval: Float64
        let parent: Lesson

        init(lesson: Lesson, row: Row) throws {
            strokes = try Stroke.parseStrokes(row[lesson.strokes])
            english = row[lesson.english]
            seq = row[lesson.seq]
            next = row[lesson.next]
            interval = row[lesson.interval]
            parent = lesson
        }

        // Update the word for a given user response.  This is given
        // as an integer giving the level of confidence, with 0
        // indicating the word was unknown.
        func update(level: Int) throws {
            // Specific notes, the new interval is taken from now, but
            // doesn't currently use the SM2 way of increasing the
            // interval based on the actual time since the word was
            // given.  This may be desired at some point.
            let now = Date()
            let newInterval: Float64
            switch level {
            case 0:
                newInterval = interval * 0.5
            case 1:
                newInterval = interval * 1.2
            case 2:
                newInterval = interval * 2.0
            case 3:
                newInterval = interval * 3.0
            default:
                print("Unknown response, keeping interval the same")
                newInterval = interval
            }

            try parent.update(seq: seq, next: now.addingTimeInterval(newInterval),
                interval: newInterval)
        }
    }
}

struct Problem {
    let strokes: [Stroke]
    let english: String
}

struct SubLesson {
    let title: String
    let include: Stroke
    let require: Stroke
    let tags: String
    let problems: [Problem]
}
