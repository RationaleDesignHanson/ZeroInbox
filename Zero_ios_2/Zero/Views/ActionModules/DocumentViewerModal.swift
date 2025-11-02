import SwiftUI

struct DocumentViewerModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool
    
    let screenplayText = """
TOMMY BOY
Written by Bonnie & Terry Turner

FADE IN:

INT. CALLAHAN AUTO FACTORY - DAY

TOMMY CALLAHAN, 27, boyish and enthusiastic, stands before the BOARD OF DIRECTORS. He's wearing a suit that's slightly too small.

TOMMY
(nervously adjusting tie)
Ladies and gentlemen, my father built this company on one principle: Quality parts at fair prices.

He trips slightly over his words, dropping his notes.

TOMMY (CONT'D)
Whoops! Fat guy in a little coat... I mean, uh... what I lack in eloquence, I make up for in heart. We're not just making brake pads. We're making sure families get home safe.

RICHARD (V.O.)
That's very touching, Tommy.

RICHARD HAYDEN enters, impeccably dressed.

RICHARD
But heart doesn't show up in quarterly reports. The board needs numbers, projections, market analysis.

Tommy fumbles with his scattered papers.

TOMMY
Right, yes! If we increase production by 15% and reduce overhead by... 
(searching frantically)
...by a number that would really impress you if I could find it!

The board members exchange glances.

CHAIRMAN
Tommy, we appreciate your passion. But running a company requires strategy, not just enthusiasm.

Tommy straightens up, determined.

TOMMY
You're right. I'm not my father. But give me one quarter, just one, and I'll prove that Callahan Auto can compete with anyone.

INT. RICHARD'S OFFICE - LATER

Richard leans back in his chair, smirking.

RICHARD
One quarter? You couldn't run a lemonade stand for one week.

TOMMY
(defensive)
I ran a very successful lemonade stand in third grade, thank you very much!

RICHARD
Did you now?

TOMMY
Made twelve dollars. Well... seven after my dad bought most of it. But still!

Richard shakes his head, amused despite himself.

RICHARD
Alright, Tommy. Here's the deal. You want to save this company? You need to hit the road. Sell. Make the clients believe in Callahan Auto again.

TOMMY
Road trip? I can do that! When do we leave?

RICHARD
"We"? Oh no. I'm not going anywhere with you.

TOMMY
Come on! It'll be fun! Like Butch and Sundance!

RICHARD
They died in the end.

TOMMY
Thelma and Louise?

RICHARD
Also died.

TOMMY
(pause)
...Turner and Hooch?

RICHARD
(sighs deeply)
Pack your bags. We leave Monday.

FADE OUT.

[END OF EXCERPT - Pages 1-3]

— Document approved for production by Legal Department
— Reviewed by Executive Team
"""
    
    var headerView: some View {
        HStack {
            Text("Document Review")
                .font(.title3.bold())
                .foregroundColor(DesignTokens.Colors.textPrimary)
            Spacer()
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(DesignTokens.Colors.textSubtle)
                    .font(.title2)
            }
        }
        .padding()
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.section) {
                        Text("TOMMY BOY")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        Text("Screenplay - Pages 1-3")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                            .padding(.bottom, DesignTokens.Spacing.inline)
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.bottom, DesignTokens.Spacing.component)
                        
                        Text(screenplayText)
                            .font(.body.monospaced())
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .lineSpacing(4)
                    }
                    .padding(DesignTokens.Spacing.card)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.3),
                                                Color.white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .padding()
                }
                
                Button {
                    isPresented = false
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark as Reviewed")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.container)
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                .padding()
        }
    }
}

