// A single steno lesson.

import Foundation
import SQLite

class Lesson {
    var problems = [Problem]()
    var subLessons = [SubLesson]()

    init(dictPath: String, lessonPath: String) {
        do {
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
        } catch {
            print("Unable to load data", error)
            // TODO: Cleaner stop
            exit(1)
        }

        // Load the lessons.
        do {
            let url = URL(fileURLWithPath: lessonPath)
            let data = try Data(contentsOf: url, options: [])
            let obj = try JSONSerialization.jsonObject(with: data, options: []) as! [Dictionary<String, String>]

            for l in obj {
                let include = try Stroke.parseStroke(l["include"]!)
                let require = try Stroke.parseStroke(l["require"]!)

                var remaining = [Problem]()
                var probs = [Problem]()

                for p in problems {
                    let p1 = p.strokes[0].value
                    if (p1 & ~include.value) == 0 && (p1 & require.value) != 0 {
                        probs.append(p)
                    } else {
                        remaining.append(p)
                    }
                }

                problems = remaining

                subLessons.append(SubLesson(title: l["title"]!,
                    include: include,
                    require: require,
                    tags: l["tags"]!,
                    problems: probs))

                // print(subLessons[subLessons.count-1])
            }
        } catch {
            print("Unable to load lesson", error)
            // TODO: Cleaner stop
            exit(1)
        }
    }

    func setupDb(db: Connection) throws {
        let words = Table("words")
        let strokes = Expression<String>("strokes")
        let seq = Expression<Int>("seq")
        let english = Expression<String>("english")
        let duration = Expression<Float64>("duration")

        try db.run(words.create { t in
            t.column(strokes, primaryKey: true)
            t.column(seq)
            t.column(english)
            t.column(duration)
        })

        var s = 1
        try db.transaction {
            for sub in self.subLessons {
                for prob in sub.problems {
                    let text = prob.strokes.map({ (_ elt: Stroke) -> String in
                        String(describing: elt)
                    }).joined(separator: "/")
                    try db.run(words.insert(strokes <- text, seq <- s, english <- prob.english, duration <- 60.0))
                    s += 1
                }
            }
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
