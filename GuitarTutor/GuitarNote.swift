
struct GuitarNote {
    let name: String
    let frequency: Float
    
    static let guitarNotes = [
        GuitarNote(name: "E2", frequency: 82.41),
        GuitarNote(name: "A2", frequency: 110.00),
        GuitarNote(name: "D3", frequency: 146.83),
        GuitarNote(name: "G3", frequency: 196.00),
        GuitarNote(name: "B3", frequency: 246.94),
        GuitarNote(name: "E4", frequency: 329.63)
    ]
    
    static func getNote(frequency: Float) -> String {
        var closestNote = Self.guitarNotes[0]
        var smallestDistance = abs(frequency - closestNote.frequency)
        
        for note in Self.guitarNotes {
            let distance = abs(frequency - note.frequency)
            
            
            if distance <  smallestDistance {
                smallestDistance = distance
                closestNote = note
            }
        }
        
        return closestNote.name
    }
}
//
//  GuitarNote.swift
//  GuitarTutor
//
//  Created by Moroni Montoya Bernal on 10/1/26.
//

