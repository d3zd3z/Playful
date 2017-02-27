// A single steno lesson.

import Foundation

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

                print(subLessons[subLessons.count-1])
            }
        } catch {
            print("Unable to load lesson", error)
            // TODO: Cleaner stop
            exit(1)
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
