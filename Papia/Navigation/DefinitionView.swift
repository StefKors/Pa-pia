//
//  DefinitionView.swift
//  Pápia
//
//  Created by Stef Kors on 02/05/2024.
//

import SwiftUI

// https://api.datamuse.com/words?ml=tree&qe=ml&md=dp&max=1
struct DefinitionView: View {
    let def: DataMuseDefinition

    private let first: String
    private let others: [String]

    init(def: DataMuseDefinition) {
        self.def = def
        var definitions = def.defs.map {
            $0.dropFirst(1).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        self.first = definitions.removeFirst()
        self.others = definitions
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if def.isNoun {
                        Text("noun")
                            .padding(.horizontal, 4)
                            .background(.background.blendMode(.multiply).opacity(0.6), in: RoundedRectangle(cornerRadius: 4))
                    }
                    
                    if def.isVerb {
                        Text("verb")
                            .padding(.horizontal, 4)
                            .background(.background.blendMode(.multiply).opacity(0.6), in: RoundedRectangle(cornerRadius: 4))
                    }
                    
                    if def.isAdjective {
                        Text("adjective")
                            .padding(.horizontal, 4)
                            .background(.background.blendMode(.multiply).opacity(0.6), in: RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                }
                .frame(alignment: .leading)
                .font(.footnote)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(first)
                        .multilineTextAlignment(.leading)
                    
                    ForEach(others, id: \.self) { definition in
                        Divider()
                        
                        Text(definition)
                            .multilineTextAlignment(.leading)
                    }
                }
                .foregroundStyle(.primary)
            }
            .lineLimit(nil)
            .font(.body)
        }
    }
}

#Preview {
    DefinitionView(def: .preview)
}
