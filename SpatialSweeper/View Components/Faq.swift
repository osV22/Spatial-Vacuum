//
//  Faq.swift
//  SpatialSweeper
//
//  Created by Ahmed G on 3/15/24.
//

import SwiftUI

struct FaqItem {
    var question: String
    var answer: String
    var isExpanded: Bool = false
}

struct Faq: View {
    @State private var faqItems: [FaqItem] = [
        FaqItem(question: "Does the \"Real\" vacuum option work with a mop, broom, leaf blower, etc?", answer: "Yes, but accuracy will vary based on how visible your hand is. The more visible your hand is, the more accurate collection will be. The 'hitbox' or collision mesh is modeled after your typical vacuum with the rectangle head doing the collection."),
        FaqItem(question: "Can you add X, Y, Z cool feature?", answer: "Maybe. You're welcome to send a PR to the repo above. I thought about adding miles walked and coins collected over time but not sure if there's interest."),
        FaqItem(question: "Can you replace the coins with bananas, X, Y, Z object instead?", answer: "Maybe. Very easy to just load a different mesh but not sure if there's enough interest to add a feature to let you select an object. PRs are more than welcome!"),
        FaqItem(question: "Can you increase the coin density?", answer: "Yes! In a future release will add a slider to let you decide the amount."),
        FaqItem(question: "How are you 'tracking' the \"Real\" vacuum?!", answer: "Wizardry! The \"Real\" option loads a different mesh with different collision that mimics your typical vacuum model. The mesh is then made invisible. That's why if you wave your hand without a real vacuum in your hand it will still collect coins. Overall, I'm attaching an invisible vacuum to your hand. Told ya, magic!"),
        FaqItem(question: "Can I donate or buy you a coffee?", answer: "Many Thanks! But I'm just happy to help, this was created as a learning experience. I am open for work as a mobile dev though, if you know someone that needs a code monkey on their team. ahmedg.pages.dev || ed@noble9.io"),
    ]
    
    var body: some View {
        List {
            ForEach($faqItems.indices, id: \.self) { index in
                DisclosureGroup(
                    isExpanded: $faqItems[index].isExpanded,
                    content: {
                        Text(faqItems[index].answer)
                            .padding()
                    },
                    label: {
                        Text(faqItems[index].question)
                            .fontWeight(.bold)
                    }
                )
            }
        }
    }
}

struct FaqView_Previews: PreviewProvider {
    static var previews: some View {
        Faq()
    }
}
