//
//  SamplePrayer.swift
//  Airplay Demo
//
//  Created on 5/5/26, all Glory goes to God.
//
//  Role in the dual-scene architecture:
//  Hardcoded public-domain content used by both the phone and TV scenes.
//  Kept as a flat [String] of display lines so PrayerSession can index into
//  it directly without any parsing or playback machinery.
//
//  Content: The Holy Rosary — Glorious Mysteries.
//  Includes the Sign of the Cross, Apostles' Creed, opening Our Father,
//  three opening Hail Marys, Glory Be, then for each of the five Glorious
//  Mysteries: the announcement, an Our Father, the Hail Mary (with a "× 10"
//  headline indicating the decade), a Glory Be, and the Fatima prayer.
//  Closes with the Hail Holy Queen.
//
//  Repeated prayers are shown once with a count headline (e.g. "Hail Mary
//  · ×10") rather than literally repeated 10 times, which keeps the line
//  list readable and demos better as a transcript.
//
//  The traditional English texts of all of these prayers predate 1923
//  and are in the public domain.
//

import Foundation

enum SamplePrayer {

    static let title = "The Holy Rosary — Glorious Mysteries"

    // MARK: - Prayer building blocks

    private static let signOfCross: [String] = [
        "In the name of the Father, and of the Son, and of the Holy Spirit. Amen."
    ]

    private static let apostlesCreed: [String] = [
        "I believe in God, the Father almighty, Creator of heaven and earth,",
        "and in Jesus Christ, his only Son, our Lord,",
        "who was conceived by the Holy Spirit,",
        "born of the Virgin Mary,",
        "suffered under Pontius Pilate, was crucified, died and was buried;",
        "he descended into hell; on the third day he rose again from the dead;",
        "he ascended into heaven, and is seated at the right hand of God the Father almighty;",
        "from there he will come to judge the living and the dead.",
        "I believe in the Holy Spirit, the holy catholic Church,",
        "the communion of saints, the forgiveness of sins,",
        "the resurrection of the body, and life everlasting. Amen."
    ]

    private static let ourFather: [String] = [
        "Our Father, who art in heaven, hallowed be thy name;",
        "thy kingdom come, thy will be done, on earth as it is in heaven.",
        "Give us this day our daily bread,",
        "and forgive us our trespasses, as we forgive those who trespass against us;",
        "and lead us not into temptation, but deliver us from evil. Amen."
    ]

    private static let hailMary: [String] = [
        "Hail Mary, full of grace, the Lord is with thee;",
        "blessed art thou amongst women,",
        "and blessed is the fruit of thy womb, Jesus.",
        "Holy Mary, Mother of God, pray for us sinners,",
        "now and at the hour of our death. Amen."
    ]

    private static let gloryBe: [String] = [
        "Glory be to the Father, and to the Son, and to the Holy Spirit;",
        "as it was in the beginning, is now, and ever shall be, world without end. Amen."
    ]

    private static let fatimaPrayer: [String] = [
        "O my Jesus, forgive us our sins,",
        "save us from the fires of hell,",
        "lead all souls to heaven,",
        "especially those in most need of thy mercy."
    ]

    private static let hailHolyQueen: [String] = [
        "Hail, holy Queen, Mother of mercy,",
        "our life, our sweetness, and our hope.",
        "To thee do we cry, poor banished children of Eve;",
        "to thee do we send up our sighs, mourning and weeping in this valley of tears.",
        "Turn then, most gracious advocate, thine eyes of mercy toward us;",
        "and after this our exile, show unto us the blessed fruit of thy womb, Jesus.",
        "O clement, O loving, O sweet Virgin Mary. Amen."
    ]

    private static let mysteryAnnouncements: [String] = [
        "The First Glorious Mystery: The Resurrection.",
        "The Second Glorious Mystery: The Ascension.",
        "The Third Glorious Mystery: The Descent of the Holy Spirit.",
        "The Fourth Glorious Mystery: The Assumption of Mary.",
        "The Fifth Glorious Mystery: The Coronation of Mary."
    ]

    // MARK: - Assembled lines

    static let lines: [String] = {
        var out: [String] = []

        // Opening: Sign of the Cross is one short line that effectively
        // announces itself, so no explicit section header here.
        out += signOfCross

        out.append("Apostles' Creed")
        out += apostlesCreed

        out.append("Our Father")
        out += ourFather

        // Three opening Hail Marys, traditionally for faith, hope, and charity.
        out.append("Hail Mary  ·  ×3")
        out += hailMary

        out.append("Glory Be")
        out += gloryBe

        // The five decades.
        for announcement in mysteryAnnouncements {
            out.append(announcement)

            out.append("Our Father")
            out += ourFather

            // A decade is ten Hail Marys; we show the headline + prayer once.
            out.append("Hail Mary  ·  ×10")
            out += hailMary

            out.append("Glory Be")
            out += gloryBe

            out.append("Fatima Prayer")
            out += fatimaPrayer
        }

        // Closing prayer.
        out.append("Hail Holy Queen")
        out += hailHolyQueen

        return out
    }()

    // MARK: - Section header classification

    /// Lines that the phone view should render with section-header
    /// styling (dimmed, slightly larger serif) instead of body text.
    /// Uses simple content matching so the data stays a flat [String].
    static func isSectionHeader(_ line: String) -> Bool {
        sectionHeaderTitles.contains(line)
            || line.hasPrefix("Hail Mary  ·")
            || line.contains("Glorious Mystery:")
    }

    private static let sectionHeaderTitles: Set<String> = [
        "Apostles' Creed",
        "Our Father",
        "Glory Be",
        "Fatima Prayer",
        "Hail Holy Queen"
    ]
}
