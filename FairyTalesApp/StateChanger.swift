//
//  StateChanger.swift
//  FairyTales
//
//  Created by Bravery on 13.10.2024.
//

import Foundation

struct StateChanger<S> {
    var apply: (inout S) -> Void

    func map(_ another: StateChanger<S>) -> StateChanger<S> {
        StateChanger { s in
            self.apply(&s)
            another.apply(&s)
        }
    }

    func flatMap<M>(_ f: @escaping (inout S) -> M) -> (inout S) -> M  {
        { s in
            self.apply(&s)
            return f(&s)
        }
    }
    
    // New function to chain multiple state changers
    func combine(with changers: StateChanger<S>...) -> StateChanger<S> {
        changers.reduce(self) { combined, changer in
            combined.map(changer)
        }
    }

    // New function to reset the state with a default value
    static func reset(to defaultValue: S) -> StateChanger<S> {
        StateChanger { s in
            s = defaultValue
        }
    }
    
    // New function to apply a transformation conditionally
      func conditional(_ condition: @escaping (S) -> Bool, _ transform: @escaping (inout S) -> Void) -> (StateChanger<S>){
          StateChanger { s in
              if condition(s) {
                  transform(&s)
              }
          }
      }
}

extension StateChanger where S == ChapterFeature.State {
    static func makeTextColored(recognizedWords: [Substring], coloredWord: @escaping (String) -> Void) -> Self {
        StateChanger<ChapterFeature.State> { state in
            for word in recognizedWords {
                let visibleWords = String(state.visibleText.characters)
                    .components(separatedBy: " ")

                for visibleWord in visibleWords {
                    if let range = visibleWord.range(of: word, options: .caseInsensitive) {
                        let matchedWord = visibleWord[range].count
                        let fullCount = visibleWord.count

                        if fullCount - matchedWord <= 3 {
                            state.visibleText.range(of: visibleWord[...]).map {
                                state.visibleText[$0].foregroundColor = .green
                            }
                            coloredWord(visibleWord)
                        }
                    }
                }
            }
        }
    }

    static func matchToAnimation(recognizedWords: [Substring]) -> Self {
        StateChanger<ChapterFeature.State> { state in
            for word in recognizedWords {
                if state.matches.contains(where: { match in
                    match.caseInsensitiveCompare(word) == .orderedSame
                }) {
                    state.playbackMode = .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
                }
            }
        }
    }
}
