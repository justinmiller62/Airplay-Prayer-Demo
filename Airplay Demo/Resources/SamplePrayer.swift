//
//  SamplePrayer.swift
//  Airplay Demo
//
//  Created on 5/5/26, all Glory goes to God.
//
//  Role in the dual-scene architecture:
//  Hardcoded public-domain content used by both the phone and TV scenes.
//  Each entry is a `PrayerLine` carrying BOTH the English and traditional
//  Latin text plus an `isHeader` flag, so the two languages stay paired
//  at the same line index. That 1-to-1 correspondence is what lets the
//  bilingual TV layout (Latin chosen) draw Latin and English side-by-side
//  on the same row, and what keeps the (topLineIndex, topLineProgress)
//  sync between phone and TV language-independent.
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
//  and are in the public domain; the Latin texts are the traditional
//  Tridentine forms, also public domain.
//

import Foundation

enum SamplePrayer {

    // Bilingual title — both surfaces read the appropriate language.
    static let title = (
        english: "The Holy Rosary — Glorious Mysteries",
        latin:   "Sanctissimum Rosarium — Mysteria Gloriosa"
    )

    // MARK: - Building blocks (parallel EN / LA)

    private static let signOfCross: [PrayerLine] = [
        .body(
            en: "In the name of the Father, and of the Son, and of the Holy Spirit. Amen.",
            la: "In nomine Patris, et Filii, et Spiritus Sancti. Amen."
        )
    ]

    private static let apostlesCreed: [PrayerLine] = [
        .body(
            en: "I believe in God, the Father almighty, Creator of heaven and earth,",
            la: "Credo in Deum, Patrem omnipotentem, Creatorem caeli et terrae,"
        ),
        .body(
            en: "and in Jesus Christ, his only Son, our Lord,",
            la: "et in Iesum Christum, Filium eius unicum, Dominum nostrum,"
        ),
        .body(
            en: "who was conceived by the Holy Spirit,",
            la: "qui conceptus est de Spiritu Sancto,"
        ),
        .body(
            en: "born of the Virgin Mary,",
            la: "natus ex Maria Virgine,"
        ),
        .body(
            en: "suffered under Pontius Pilate, was crucified, died and was buried;",
            la: "passus sub Pontio Pilato, crucifixus, mortuus, et sepultus,"
        ),
        .body(
            en: "he descended into hell; on the third day he rose again from the dead;",
            la: "descendit ad inferos, tertia die resurrexit a mortuis,"
        ),
        .body(
            en: "he ascended into heaven, and is seated at the right hand of God the Father almighty;",
            la: "ascendit ad caelos, sedet ad dexteram Dei Patris omnipotentis,"
        ),
        .body(
            en: "from there he will come to judge the living and the dead.",
            la: "inde venturus est iudicare vivos et mortuos."
        ),
        .body(
            en: "I believe in the Holy Spirit, the holy catholic Church,",
            la: "Credo in Spiritum Sanctum, sanctam Ecclesiam catholicam,"
        ),
        .body(
            en: "the communion of saints, the forgiveness of sins,",
            la: "sanctorum communionem, remissionem peccatorum,"
        ),
        .body(
            en: "the resurrection of the body, and life everlasting. Amen.",
            la: "carnis resurrectionem, vitam aeternam. Amen."
        )
    ]

    private static let ourFather: [PrayerLine] = [
        .body(
            en: "Our Father, who art in heaven, hallowed be thy name;",
            la: "Pater noster, qui es in caelis, sanctificetur nomen tuum,"
        ),
        .body(
            en: "thy kingdom come, thy will be done, on earth as it is in heaven.",
            la: "adveniat regnum tuum, fiat voluntas tua, sicut in caelo et in terra."
        ),
        .body(
            en: "Give us this day our daily bread,",
            la: "Panem nostrum quotidianum da nobis hodie,"
        ),
        .body(
            en: "and forgive us our trespasses, as we forgive those who trespass against us;",
            la: "et dimitte nobis debita nostra, sicut et nos dimittimus debitoribus nostris,"
        ),
        .body(
            en: "and lead us not into temptation, but deliver us from evil. Amen.",
            la: "et ne nos inducas in tentationem, sed libera nos a malo. Amen."
        )
    ]

    private static let hailMary: [PrayerLine] = [
        .body(
            en: "Hail Mary, full of grace, the Lord is with thee;",
            la: "Ave Maria, gratia plena, Dominus tecum,"
        ),
        .body(
            en: "blessed art thou amongst women,",
            la: "benedicta tu in mulieribus,"
        ),
        .body(
            en: "and blessed is the fruit of thy womb, Jesus.",
            la: "et benedictus fructus ventris tui, Iesus."
        ),
        .body(
            en: "Holy Mary, Mother of God, pray for us sinners,",
            la: "Sancta Maria, Mater Dei, ora pro nobis peccatoribus,"
        ),
        .body(
            en: "now and at the hour of our death. Amen.",
            la: "nunc et in hora mortis nostrae. Amen."
        )
    ]

    private static let gloryBe: [PrayerLine] = [
        .body(
            en: "Glory be to the Father, and to the Son, and to the Holy Spirit;",
            la: "Gloria Patri, et Filio, et Spiritui Sancto,"
        ),
        .body(
            en: "as it was in the beginning, is now, and ever shall be, world without end. Amen.",
            la: "sicut erat in principio, et nunc, et semper, et in saecula saeculorum. Amen."
        )
    ]

    private static let fatimaPrayer: [PrayerLine] = [
        .body(
            en: "O my Jesus, forgive us our sins,",
            la: "Domine Iesu, dimitte nobis debita nostra,"
        ),
        .body(
            en: "save us from the fires of hell,",
            la: "salva nos ab igne inferiori,"
        ),
        .body(
            en: "lead all souls to heaven,",
            la: "perduc in caelum omnes animas,"
        ),
        .body(
            en: "especially those in most need of thy mercy.",
            la: "praesertim eas, quae misericordiae tuae maxime indigent."
        )
    ]

    private static let hailHolyQueen: [PrayerLine] = [
        .body(
            en: "Hail, holy Queen, Mother of mercy,",
            la: "Salve, Regina, Mater misericordiae,"
        ),
        .body(
            en: "our life, our sweetness, and our hope.",
            la: "vita, dulcedo, et spes nostra, salve."
        ),
        .body(
            en: "To thee do we cry, poor banished children of Eve;",
            la: "Ad te clamamus exsules filii Hevae,"
        ),
        .body(
            en: "to thee do we send up our sighs, mourning and weeping in this valley of tears.",
            la: "ad te suspiramus, gementes et flentes in hac lacrimarum valle."
        ),
        .body(
            en: "Turn then, most gracious advocate, thine eyes of mercy toward us;",
            la: "Eia ergo, advocata nostra, illos tuos misericordes oculos ad nos converte,"
        ),
        .body(
            en: "and after this our exile, show unto us the blessed fruit of thy womb, Jesus.",
            la: "et Iesum, benedictum fructum ventris tui, nobis post hoc exsilium ostende."
        ),
        .body(
            en: "O clement, O loving, O sweet Virgin Mary. Amen.",
            la: "O clemens, O pia, O dulcis Virgo Maria. Amen."
        )
    ]

    /// Headline pairs for each Glorious Mystery announcement. Rendered
    /// with section-header styling on both surfaces.
    private static let mysteryAnnouncements: [PrayerLine] = [
        .header(
            en: "The First Glorious Mystery: The Resurrection.",
            la: "Mysterium Gloriosum Primum: Resurrectio Domini."
        ),
        .header(
            en: "The Second Glorious Mystery: The Ascension.",
            la: "Mysterium Gloriosum Secundum: Ascensio Domini."
        ),
        .header(
            en: "The Third Glorious Mystery: The Descent of the Holy Spirit.",
            la: "Mysterium Gloriosum Tertium: Descensus Spiritus Sancti."
        ),
        .header(
            en: "The Fourth Glorious Mystery: The Assumption of Mary.",
            la: "Mysterium Gloriosum Quartum: Assumptio Beatae Mariae Virginis."
        ),
        .header(
            en: "The Fifth Glorious Mystery: The Coronation of Mary.",
            la: "Mysterium Gloriosum Quintum: Coronatio Beatae Mariae Virginis."
        )
    ]

    // MARK: - Section headers (titles)

    private static let apostlesCreedHeader: PrayerLine = .header(
        en: "Apostles' Creed",
        la: "Symbolum Apostolorum"
    )
    private static let ourFatherHeader: PrayerLine = .header(
        en: "Our Father",
        la: "Pater Noster"
    )
    private static let openingHailMarysHeader: PrayerLine = .header(
        en: "Hail Mary  ·  ×3",
        la: "Ave Maria  ·  ×3"
    )
    private static let decadeHailMaryHeader: PrayerLine = .header(
        en: "Hail Mary  ·  ×10",
        la: "Ave Maria  ·  ×10"
    )
    private static let gloryBeHeader: PrayerLine = .header(
        en: "Glory Be",
        la: "Gloria Patri"
    )
    private static let fatimaPrayerHeader: PrayerLine = .header(
        en: "Fatima Prayer",
        la: "Oratio Fatimae"
    )
    private static let hailHolyQueenHeader: PrayerLine = .header(
        en: "Hail Holy Queen",
        la: "Salve Regina"
    )

    // MARK: - Assembled lines

    static let lines: [PrayerLine] = {
        var out: [PrayerLine] = []

        // Opening: Sign of the Cross is one short line that effectively
        // announces itself, so no explicit section header here.
        out += signOfCross

        out.append(apostlesCreedHeader)
        out += apostlesCreed

        out.append(ourFatherHeader)
        out += ourFather

        // Three opening Hail Marys, traditionally for faith, hope, and charity.
        out.append(openingHailMarysHeader)
        out += hailMary

        out.append(gloryBeHeader)
        out += gloryBe

        // The five decades.
        for announcement in mysteryAnnouncements {
            out.append(announcement)

            out.append(ourFatherHeader)
            out += ourFather

            // A decade is ten Hail Marys; we show the headline + prayer once.
            out.append(decadeHailMaryHeader)
            out += hailMary

            out.append(gloryBeHeader)
            out += gloryBe

            out.append(fatimaPrayerHeader)
            out += fatimaPrayer
        }

        // Closing prayer.
        out.append(hailHolyQueenHeader)
        out += hailHolyQueen

        return out
    }()
}

// MARK: - PrayerLine convenience constructors

private extension PrayerLine {
    static func body(en: String, la: String) -> PrayerLine {
        PrayerLine(english: en, latin: la, isHeader: false)
    }
    static func header(en: String, la: String) -> PrayerLine {
        PrayerLine(english: en, latin: la, isHeader: true)
    }
}
