import Foundation

struct DataGenerator {
    private static let mockDataLoader = MockDataLoader()

    static func generateSarahChenEmails() -> [EmailCard] {
        // Use comprehensive mock data with full action set per archetype
        return generateComprehensiveMockData()
    }

    static func generateBasicEmails() -> [EmailCard] {
        return generateComprehensiveMockData()
    }

    /// Comprehensive mock data showcasing all action types per archetype
    /// HYBRID APPROACH: Loads from JSON fixtures when available, falls back to hardcoded
    static func generateComprehensiveMockData() -> [EmailCard] {
        var cards: [EmailCard] = []

        // MARK: - TRY LOADING FROM JSON FIXTURES FIRST
        do {
            let jsonEmails = try mockDataLoader.loadAllEmails()
            if !jsonEmails.isEmpty {
                Logger.info("Loaded \(jsonEmails.count) emails from JSON fixtures", category: .service)
                cards.append(contentsOf: jsonEmails)
            }
        } catch {
            Logger.warning("Failed to load JSON fixtures, using hardcoded fallback: \(error)", category: .service)
        }

        // MARK: - CORPUS-INSPIRED EMAILS (Realistic variety from analysis)
        // These are synthetic emails based on real-world patterns - NO personal data
        // NOTE: CorpusEmails.swift was removed during Week 1 cleanup - unused service
        // cards.append(contentsOf: generateCorpusInspiredEmails())

        // MARK: - NEWSLETTERS (3 cards)

        // Newsletter: Tech newsletter
        cards.append(EmailCard(
            id: "newsletter1",
            type: .mail,
            state: .unseen,
            priority: .medium,
            hpa: "View Summary",
            timeAgo: "2h ago",
            title: "The Download: This Week in AI - Issue #47",
            summary: "Weekly AI and tech newsletter featuring GPT-5 speculation, EU AI Act launch, and GitHub Copilot X upgrade. Industry stats show 67% of developers now use AI assistants daily with $21B invested this quarter.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Context:**
            • GPT-5 speculation, EU AI Act goes live, GitHub Copilot X upgrade
            • 67% of devs use AI assistants daily, $21B invested this quarter
            • Weekly digest with top stories, tools, and learning resources
            """,

            body: "THE DOWNLOAD\nYour weekly AI & tech newsletter\nIssue #47 - October 23, 2025\n\n📰 TOP STORIES THIS WEEK\n\n1. GPT-5 Speculation Heats Up\nOpenAI hints at next-generation model with improved reasoning capabilities. Sources say training began in Q3 2025. Expected launch: early 2026.\n\n2. EU AI Act Goes Into Effect\nNew regulations require transparency in AI-generated content and model training data disclosure. US companies scramble to comply.\n\n3. GitHub Copiloh X Gets Major Upgrade\nNew features include voice-to-code, AI code reviews, and context-aware suggestions across entire codebases.\n\n🔧 TOOLS & RESOURCES\n\n• LangChain 0.3 released with improved streaming\n• New Anthropic Claude API features\n• Open-source alternatives to ChatGPT gaining traction\n• Vector database comparison guide\n\n🎓 LEARNING\n\n• Free course: Building production LLM apps\n• Prompt engineering best practices 2025\n• Fine-tuning vs RAG: When to use which\n\n📊 BY THE NUMBERS\n\n• 67% of developers now use AI coding assistants daily\n• $21B invested in AI startups this quarter\n• 3.2M AI-related jobs posted in October\n\n🔮 WHAT'S NEXT\n\nNext week: Interview with Anthropic's CEO on Claude's future, plus a deep dive into multi-modal AI applications.\n\nHappy coding!\nThe TechCrunch Team",
            htmlBody: nil,
            metaCTA: "Swipe Right: View AI Summary",
            intent: "generic.newsletter",
            intentConfidence: 0.98,
            suggestedActions: [
                EmailAction(actionId: "view_newsletter_summary", displayName: "View Summary", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "save_for_later", displayName: "Save for Later", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "archive", displayName: "Archive", actionType: .inApp, isPrimary: false, priority: 3)
            ],
            sender: SenderInfo(name: "TechCrunch", initial: "T", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil,
            keyLinks: [
                EmailCard.NewsletterLink(
                    title: "GPT-5 Speculation Heats Up",
                    url: "https://techcrunch.com/gpt5-analysis",
                    description: "OpenAI hints at next-generation model with improved reasoning capabilities."
                ),
                EmailCard.NewsletterLink(
                    title: "EU AI Act Goes Into Effect",
                    url: "https://techcrunch.com/eu-ai-act",
                    description: "New regulations require transparency in AI-generated content and training data disclosure."
                ),
                EmailCard.NewsletterLink(
                    title: "GitHub Copilot X Upgrade",
                    url: "https://github.com/features/copilot",
                    description: "Voice-to-code, AI code reviews, and context-aware suggestions across entire codebases."
                )
            ],
            keyTopics: ["Artificial Intelligence", "GPT-5", "EU Regulation", "GitHub", "Machine Learning"]
        ))

        // Newsletter: Product/Shopping newsletter
        cards.append(EmailCard(
            id: "newsletter2",
            type: .ads,
            state: .unseen,
            priority: .medium,
            hpa: "View Summary",
            timeAgo: "5h ago",
            title: "Avant Arte Weekly: New Drops & Artist Spotlights",
            summary: "Weekly art newsletter featuring new limited edition releases from James Jean ($850), KAWS ($650), and Takashi Murakami ($450). Premium early access starts tomorrow for members.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Context:**
            • James Jean ($850), KAWS ($650), Murakami ($450) dropping this week
            • Premium early access available tomorrow
            • Collector's Corner guide and market trends included
            """,

            body: "AVANT ARTE WEEKLY\nYour curated art newsletter\nOctober 23, 2025\n\n🎨 THIS WEEK'S DROPS\n\n1. James Jean - \"Celestial Mechanics\" Series\nLaunching Thursday, October 31 at 12 PM EST\nLimited edition print + sculpture duo\nEdition of 100 | $850\nJames discusses his inspiration from astrophysics and ancient mythology. This collection bridges science and spirituality through intricate linework and cosmic imagery.\n→ Set your alarm | Schedule purchase\n\n2. KAWS - \"Companion Floral\" Prints\nReleasing Friday, November 1 at 10 AM EST  \nSilkscreen print on archival paper\nEdition of 200 | $650\nThe iconic Companion reimagined in a field of wildflowers. KAWS explores themes of solitude and natural beauty in urban environments.\n→ Preview collection\n\n3. Takashi Murakami - \"Rainbow Flower\" Editions\nDropping Saturday, November 2 at 11 AM EST\nGiclee print with hand-finished details  \nEdition of 300 | $450\nMurakami's signature flower motif in vibrant new colorways. Each print includes artist's embossed seal.\n→ View artist statement\n\n📚 ARTIST SPOTLIGHT\n\nIn Conversation with Kehinde Wiley\nThe renowned portrait artist discusses his latest body of work exploring Black excellence and classical European painting traditions. Read the full interview about his process, inspiration, and upcoming museum exhibitions.\n→ Read interview (8 min)\n\n💡 COLLECTOR'S CORNER\n\n• How to properly frame limited edition prints\n• Investment potential of emerging artists\n• Understanding edition sizes and artist proofs\n• Climate-controlled storage tips\n→ Read collector's guide\n\n📊 MARKET WATCH\n\nTrending Artists This Month:\n• Loish - Fantasy illustration (↑ 45%)\n• Daniel Arsham - Contemporary sculpture (↑ 32%)\n• Yoshitomo Nara - Japanese pop art (↑ 28%)\n\n🎁 MEMBER EXCLUSIVE\n\nEarly access to November drops starts tomorrow for Premium members. Upgrade today for 48-hour advance notice on all releases.\n→ Upgrade to Premium | Learn more\n\n---\n\nHappy collecting!\nThe Avant Arte Team\n\nManage preferences | Unsubscribe",
            htmlBody: nil,
            metaCTA: "Swipe Right: View AI Summary",
            intent: "generic.newsletter",
            intentConfidence: 0.96,
            suggestedActions: [
                EmailAction(actionId: "view_newsletter_summary", displayName: "View Summary", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "schedule_purchase", displayName: "Schedule Purchase", actionType: .inApp, isPrimary: false, priority: 2, context: ["saleDate": "31 October", "productUrl": "https://avantarte.com/james-jean-celestial", "productName": "James Jean - Celestial Mechanics"]),
                EmailAction(actionId: "save_for_later", displayName: "Save for Later", actionType: .inApp, isPrimary: false, priority: 3),
                EmailAction(actionId: "unsubscribe", displayName: "Unsubscribe", actionType: .goTo, isPrimary: false, priority: 4, context: ["unsubscribeUrl": "https://avantarte.com/unsubscribe"])
            ],
            sender: SenderInfo(name: "Avant Arte", initial: "A", email: nil),
            kid: nil,
            company: nil,
            store: "Avant Arte",
            airline: nil,
            productImageUrl: "https://images.unsplash.com/photo-1547826039-bfc35e0f1ea8?w=400",
            brandName: "Various Artists",
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil,
            keyLinks: [
                EmailCard.NewsletterLink(
                    title: "James Jean - Celestial Mechanics Series",
                    url: "https://avantarte.com/james-jean-celestial",
                    description: "Limited edition print + sculpture duo. Edition of 100 | $850. Launching Oct 31, 12 PM EST."
                ),
                EmailCard.NewsletterLink(
                    title: "KAWS - Companion Floral Prints",
                    url: "https://avantarte.com/kaws-companion-floral",
                    description: "Silkscreen print on archival paper. Edition of 200 | $650. Releasing Nov 1, 10 AM EST."
                ),
                EmailCard.NewsletterLink(
                    title: "Takashi Murakami - Rainbow Flower",
                    url: "https://avantarte.com/murakami-rainbow-flower",
                    description: "Giclee print with hand-finished details. Edition of 300 | $450. Dropping Nov 2, 11 AM EST."
                )
            ],
            keyTopics: ["Art", "Limited Edition", "James Jean", "KAWS", "Murakami"]
        ))

        // Newsletter: Company/Team newsletter
        cards.append(EmailCard(
            id: "newsletter3",
            type: .mail,
            state: .unseen,
            priority: .low,
            hpa: "View Summary",
            timeAgo: "1d ago",
            title: "Team Bulletin: October Edition - Q4 Updates",
            summary: "Company exceeded Q3 targets by 18% with $12.4M revenue. Annual offsite at Lake Tahoe Nov 5-6 - RSVP required by October 28.",

            aiGeneratedSummary: """
            **Actions:**
            • RSVP for Lake Tahoe offsite by **October 28**

            **Context:**
            • Q3 exceeded targets by 18% ($12.4M revenue)
            • Company offsite Nov 5-6, All-Hands Nov 15
            • New hires, Q4 goals, and learning opportunities included
            """,

            body: "TEAM BULLETIN\nOctober 2025 Edition\n\n📊 COMPANY HIGHLIGHTS\n\nQ3 Results Are In!\nWe exceeded our quarterly targets by 18% - our strongest quarter yet. Revenue hit $12.4M with 2,400 new customers added.\n\nKey Metrics:\n• Customer growth: +32% YoY\n• Employee satisfaction: 4.6/5.0\n• Product uptime: 99.97%\n• Net Promoter Score: 72 (Industry avg: 45)\n\n🏆 TEAM ACHIEVEMENTS\n\nEngineering:\n• Shipped AI-powered search feature (2 weeks ahead of schedule)\n• Reduced page load times by 40%\n• Zero critical bugs in production this quarter\n\nSales:\n• Closed 3 enterprise deals ($1.2M total ARR)\n• Expanded into EMEA region\n• Hit 120% of quarterly quota\n\nCustomer Success:\n• Maintained 98% customer retention rate\n• NPS increased from 68 to 72\n• Reduced average response time to 2.3 hours\n\n👏 SPOTLIGHT: Employee of the Month\n\nCongratulations to Sarah Chen (Engineering) for her exceptional work leading the AI search project. Sarah worked cross-functionally with Product, Design, and Data teams to deliver a feature that's already driving 25% more user engagement.\n\n📅 UPCOMING EVENTS\n\nNov 5-6: Annual Company Offsite\nLocation: Lake Tahoe\nActivities: Strategic planning, team building, celebration dinner\nRSVP by Oct 28\n→ Register here\n\nNov 15: All-Hands Q&A with CEO\nFormat: Virtual town hall\nTime: 2:00 PM PST\nSubmit questions in advance\n→ Submit questions\n\nNov 22: Thanksgiving Week - Office Closed\nEnjoy time with family!\n\n🎯 Q4 GOALS\n\n1. Launch mobile app (iOS & Android)\n2. Reach 3,000 total customers\n3. Expand engineering team by 5 hires\n4. Achieve SOC 2 Type II certification\n5. Ship real-time collaboration features\n\nProgress tracking dashboards available on company intranet.\n\n💼 NEW HIRES\n\nWelcome to the team:\n• Alex Rodriguez - Senior Product Designer\n• Priya Patel - Data Scientist\n• Marcus Johnson - Account Executive\n• Emily Zhang - DevOps Engineer\n\n🎓 LEARNING & DEVELOPMENT\n\nNew courses available:\n• Advanced React patterns (Engineering)\n• Negotiation skills workshop (Sales)\n• Leadership fundamentals (All managers)\n• AI/ML fundamentals (All employees)\n\nEducation budget: $1,500/year per employee\n→ Browse course catalog\n\n🎉 SOCIAL\n\nTeam Happy Hour - This Friday!\nLocation: The Local Tap\nTime: 5:00 PM\nFirst round on the company\nRSVP appreciated\n\n---\n\nQuestions? Feedback? Reply to this email or ping People Ops on Slack.\n\nCheers,\nThe Leadership Team\n\nRead previous editions | Update preferences",
            htmlBody: nil,
            metaCTA: "Swipe Right: View AI Summary",
            intent: "generic.newsletter",
            intentConfidence: 0.94,
            suggestedActions: [
                EmailAction(actionId: "view_newsletter_summary", displayName: "View Summary", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "rsvp_yes", displayName: "RSVP to Offsite", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "save_for_later", displayName: "Save for Later", actionType: .inApp, isPrimary: false, priority: 3)
            ],
            sender: SenderInfo(name: "Leadership Team", initial: "L", email: nil),
            kid: nil,
            company: CompanyInfo(name: "Your Company", initials: "YC"),
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil,
            keyLinks: [
                EmailCard.NewsletterLink(
                    title: "RSVP for Company Offsite",
                    url: "https://company.com/offsite-rsvp",
                    description: "Annual offsite at Lake Tahoe, Nov 5-6. Strategic planning, team building, celebration dinner."
                ),
                EmailCard.NewsletterLink(
                    title: "Submit Questions for All-Hands",
                    url: "https://company.com/allhands-questions",
                    description: "Virtual town hall with CEO on Nov 15, 2:00 PM PST. Submit your questions in advance."
                ),
                EmailCard.NewsletterLink(
                    title: "Browse Learning & Development Courses",
                    url: "https://company.com/learning-catalog",
                    description: "New courses available: React, negotiation skills, leadership, AI/ML. $1,500/year education budget."
                )
            ],
            keyTopics: ["Company News", "Q3 Results", "Team Offsite", "All-Hands", "Learning"]
        ))

        // MARK: - FAMILY (4 actions)

        // sign_form
        cards.append(EmailCard(
            id: "edu1",
            type: .mail,
            state: .unseen,
            priority: .critical,
            hpa: "Sign & Send",
            timeAgo: "2h ago",
            title: "Field Trip Permission - Due Wednesday",
            summary: "Emma's 3rd grade class is going to the Natural History Museum this Friday. Permission form and $25 fee due by Wednesday at 5 PM.",

            aiGeneratedSummary: """
            **Actions:**
            • Sign permission form by **Wednesday 5 PM**
            • Pay $25 trip fee online

            **Context:**
            • Trip includes dinosaur exhibits and planetarium show
            • Departure 8:30 AM, return 2:30 PM
            • Pack lunch and water bottle
            """,

            body: """
            Dear Parents and Guardians,

            We are excited to announce that Emma's 3rd grade class will be taking a field trip to the Natural History Museum this Friday, October 27th!

            IMPORTANT: Permission forms and payment are due by Wednesday, October 25th at 5:00 PM.

            Trip Details:
            • Departure: 8:30 AM from school
            • Return: 2:30 PM
            • Cost: $25 per student (covers admission and bus transportation)

            Activities:
            • Guided tour of the dinosaur fossil exhibit
            • Interactive planetarium show: "Journey Through the Solar System"
            • Lunch in the museum courtyard (students must bring their own lunch)

            What to Bring:
            • Signed permission form (attached)
            • Packed lunch and water bottle
            • Weather-appropriate clothing (we'll be outside for lunch)

            Payment Options:
            1. Online: Visit school.com/pay-fee and enter student ID
            2. Check: Make payable to "Lincoln Elementary" and send with your child

            This is a wonderful educational opportunity that aligns with our science curriculum on Earth history and astronomy. We hope all students can attend!

            If you have any questions or concerns, please don't hesitate to reach out.

            Best regards,
            Mrs. Johnson
            3rd Grade Teacher
            Lincoln Elementary School
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Sign, Pay & Send",
            threadLength: 3,
            intent: "education.permission.form",
            intentConfidence: 1.0,
            suggestedActions: [
                EmailAction(actionId: "sign_form", displayName: "Sign & Send", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "pay_form_fee", displayName: "Pay Fee", actionType: .goTo, isPrimary: false, priority: 2, context: ["amount": "25.00", "paymentUrl": "https://school.com/pay-fee"]),
                EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 3)
            ],
            sender: nil,
            kid: KidInfo(name: "Emma Chen", initial: "E", grade: "3rd Grade"),
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: true,
            paymentAmount: 25.0,
            paymentDescription: "Field Trip Fee",
            value: nil,
            probability: nil,
            score: nil
        ))

        // pay_form_fee
        cards.append(EmailCard(
            id: "edu2",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "Pay Fee",
            timeAgo: "5h ago",
            title: "Yearbook Fee Due - $35",
            summary: "Last chance to order Lucas's 2025 yearbook at early-bird price of $35. Orders close next Friday before price increases to $45.",

            aiGeneratedSummary: """
            **Actions:**
            • Pay $35 yearbook fee by **next Friday**

            **Why:**
            Last chance to order 2025 yearbook before prices increase.

            **Context:**
            • Pay online via school portal or send check with Lucas
            • Includes photo pages, club activities, and memories section
            """,

            body: """
            Dear Families,

            This is your LAST CHANCE to order the 2025 Lincoln Middle School Yearbook at the early-bird price!

            Orders close NEXT FRIDAY, November 3rd at midnight.

            Pricing:
            • Order by Nov 3rd: $35
            • After Nov 3rd: $45 (limited quantities)
            • At year-end: $50 (if any remaining)

            What's Inside:
            ✓ Full-color photo pages from every grade
            ✓ Club and sports team photos
            ✓ Special events coverage (dances, assemblies, field trips)
            ✓ Student spotlight pages
            ✓ "Memories" section with student quotes and fun facts

            How to Order:
            1. Online: Visit school.com/yearbook and pay with credit card
            2. Check: Send $35 check (payable to "Lincoln PTA") with Lucas

            Don't miss out on preserving these middle school memories! Yearbooks make wonderful keepsakes and are especially treasured during graduation.

            Questions? Contact the yearbook committee at yearbook@lincoln.edu

            Thank you for your support!

            Lincoln Middle School PTA
            Yearbook Committee
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Pay Fee",
            threadLength: 4,
            intent: "education.payment.request",
            intentConfidence: 0.95,
            suggestedActions: [
                EmailAction(actionId: "pay_form_fee", displayName: "Pay Fee", actionType: .goTo, isPrimary: true, priority: 1, context: ["amount": "35.00", "url": "https://school.com/yearbook"]),
                EmailAction(actionId: "add_reminder", displayName: "Remind Me", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: nil,
            kid: KidInfo(name: "Lucas Chen", initial: "L", grade: "7th Grade"),
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: 35.0,
            paymentDescription: "Yearbook Fee",
            value: nil,
            probability: nil,
            score: nil
        ))

        // view_assignment
        cards.append(EmailCard(
            id: "edu3",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "View Assignment",
            timeAgo: "8h ago",
            title: "Assignment Past Due - Math Homework",
            summary: "Lucas's Chapter 5 math homework is past due and must be submitted by Friday 3 PM to avoid a 10% late penalty. Covers fractions, decimals, and word problems.",

            aiGeneratedSummary: """
            **Actions:**
            • Submit Chapter 5 homework (problems 1-24) by **Friday 3 PM** to avoid late penalty

            **Why:**
            Assignment is past due and needs immediate submission.

            **Context:**
            • Covers fractions, decimals, and word problems
            """,
            body: """
            Dear Parents/Guardians,

            This is an urgent reminder that Lucas has a past-due assignment in Math that requires immediate attention.

            Assignment Details:
            • Chapter 5 Homework: Problems 1-24
            • Original Due Date: Monday, October 23rd
            • Extended Deadline: Friday, October 27th at 3:00 PM
            • Late Penalty: 10% deduction if not submitted by Friday

            Topics Covered:
            ✓ Converting between fractions and decimals
            ✓ Adding and subtracting mixed numbers
            ✓ Real-world word problems with decimals
            ✓ Simplifying complex fractions

            The assignment is available in Google Classroom and should take approximately 45-60 minutes to complete. Students are encouraged to show their work for partial credit.

            If Lucas is having difficulty with any of the concepts, please encourage him to:
            1. Review the example problems in Chapter 5 (pages 112-118)
            2. Watch the tutorial videos posted in Google Classroom
            3. Attend Tuesday/Thursday after-school math help (3:00-4:00 PM)
            4. Email me directly with specific questions

            Please ensure Lucas completes and submits this assignment by Friday to avoid the late penalty. This homework counts toward his overall grade and reinforces essential skills for our upcoming unit test.

            Thank you for your support in keeping Lucas on track!

            Best regards,
            Mr. Thompson
            7th Grade Math Teacher
            Lincoln Middle School
            mthompson@lincoln.edu
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: View Assignment",
            intent: "education.homework.reminder",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "view_assignment", displayName: "View Assignment", actionType: .goTo, isPrimary: true, priority: 1, context: ["url": "https://classroom.google.com/assignment-123"]),
                EmailAction(actionId: "add_reminder", displayName: "Add Reminder", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: nil,
            kid: KidInfo(name: "Lucas Chen", initial: "L", grade: "7th Grade"),
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // check_grade
        cards.append(EmailCard(
            id: "edu4",
            type: .mail,
            state: .unseen,
            priority: .medium,
            hpa: "Check Grade",
            timeAgo: "1d ago",
            title: "Science Project Graded - 95/100",
            summary: "Emma earned an excellent 95/100 on her solar system project. Teacher praised her planet research and detailed Saturn's rings recreation.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            Emma's solar system project has been graded and received excellent marks.

            **Context:**
            • Scored 95/100 on solar system model
            • Teacher praised planet research and Saturn's rings detail
            """,
            body: """
            Dear Parents and Guardians,

            I'm pleased to inform you that Emma's solar system project has been graded, and she earned an excellent score of 95 out of 100!

            Project Grade Breakdown:
            • Research Quality: 25/25 points
            • Model Accuracy: 23/25 points (excellent planet placement and scale representation)
            • Creativity & Presentation: 24/25 points
            • Written Report: 23/25 points

            Highlights:
            Emma did outstanding work on this project. Her research on each planet was thorough and accurate, showing deep understanding of planetary characteristics. I was particularly impressed by her detailed recreation of Saturn's rings using layered materials, which demonstrated both creativity and scientific accuracy.

            Areas of Excellence:
            ✓ Comprehensive planet fact sheets with accurate data
            ✓ Creative use of materials for planet textures
            ✓ Attention to detail in Saturn's ring system
            ✓ Clear, well-organized written report

            Growth Opportunity:
            For future projects, Emma could enhance her work by including more about the planets' moons and their significance in our understanding of the solar system.

            Emma's project is currently on display in our classroom science corner. Feel free to stop by during parent visiting hours (Mon-Wed 3:30-4:30 PM) to see her excellent work!

            Keep up the fantastic work, Emma!

            Best regards,
            Mrs. Johnson
            3rd Grade Science Teacher
            Lincoln Elementary School
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Check Grade",
            intent: "education.grade.notification",
            intentConfidence: 0.90,
            suggestedActions: [
                EmailAction(actionId: "check_grade", displayName: "Check Grade", actionType: .goTo, isPrimary: true, priority: 1, context: ["url": "https://gradebook.com/view-grade"]),
                EmailAction(actionId: "view_details", displayName: "View Feedback", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: nil,
            kid: KidInfo(name: "Emma Chen", initial: "E", grade: "3rd Grade"),
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // MARK: - SHOPPING (10 actions)

        // claim_deal
        cards.append(EmailCard(
            id: "shop1",
            type: .ads,
            state: .unseen,
            priority: .high,
            hpa: "Claim Deal",
            timeAgo: "1h ago",
            title: "Sony WH-1000XM5 Headphones",
            summary: "Flash sale on Sony WH-1000XM5 noise-cancelling headphones - 30% off at $279.99 (save $120). Industry-leading audio with 30-hour battery, ends tonight at midnight.",

            aiGeneratedSummary: """
            **Actions:**
            • Claim 30% off deal **today only** (saves $120)

            **Why:**
            Limited-time flash sale on premium noise-cancelling headphones.

            **Context:**
            • Industry-leading noise cancellation, 30hr battery
            • LDAC audio, multi-point connectivity
            • Free shipping + 30-day returns
            """,
            body: """
            FLASH SALE ALERT - TODAY ONLY!

            Premium Audio at an Unbeatable Price

            Get the Sony WH-1000XM5 Wireless Noise-Cancelling Headphones for 30% OFF - today only! Save $120 on the industry's best noise-cancelling technology.

            SALE PRICE: $279.99 (Regular $399.99)
            PROMO CODE: Already applied at checkout
            SALE ENDS: Tonight at midnight

            Why Customers Love the WH-1000XM5:
            ⭐ Industry-leading noise cancellation with 8 microphones
            ⭐ 30-hour battery life on a single charge
            ⭐ Hi-Res Audio with LDAC codec support
            ⭐ Multi-point connectivity - connect two devices simultaneously
            ⭐ Lightweight, premium comfort for all-day wear
            ⭐ Adaptive Sound Control adjusts to your environment

            Perfect For:
            • Travel and commuting
            • Working from home
            • Music enthusiasts
            • Podcast and audiobook lovers

            What's Included:
            ✓ Sony WH-1000XM5 Headphones
            ✓ Carrying case
            ✓ USB-C charging cable
            ✓ Audio cable for wired listening
            ✓ 1-year manufacturer warranty

            FREE SHIPPING + FREE RETURNS
            No-hassle 30-day return policy - try them risk-free!

            Don't miss out - this flash sale price won't last! Click below to claim your deal before midnight.

            SHOP NOW: bestbuy.com/sony-wh1000xm5

            Questions? Our audio experts are here to help: 1-800-BESTBUY

            Best Buy
            Your Tech Destination
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Claim Deal Now",
            threadLength: 2,
            intent: "e-commerce.promotional.deal",
            intentConfidence: 0.95,
            suggestedActions: [
                EmailAction(actionId: "claim_deal", displayName: "Claim Deal", actionType: .goTo, isPrimary: true, priority: 1, context: ["productUrl": "https://www.bestbuy.com/site/sony-wh1000xm5-wireless-noise-canceling-over-the-ear-headphones-black/6505727.p"]),
                EmailAction(actionId: "save_deal", displayName: "Save for Later", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "compare", displayName: "Compare Prices", actionType: .goTo, isPrimary: false, priority: 3, context: ["comparisonUrl": "https://camelcamelcamel.com/product/sony-wh1000xm5"]),
                EmailAction(actionId: "unsubscribe", displayName: "Unsubscribe", actionType: .goTo, isPrimary: false, priority: 4, context: ["unsubscribeUrl": "https://bestbuy.com/unsubscribe"])
            ],
            sender: nil,
            kid: nil,
            company: nil,
            store: "Best Buy",
            airline: nil,
            productImageUrl: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400",
            brandName: "Sony",
            originalPrice: 399.99,
            salePrice: 279.99,
            discount: 30,
            urgent: true,
            expiresIn: "6 hours",
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // copy_promo_code
        cards.append(EmailCard(
            id: "shop2",
            type: .ads,
            state: .unseen,
            priority: .medium,
            hpa: "Copy Code",
            timeAgo: "3h ago",
            title: "Extra 20% Off - Code: SAVE20",
            summary: "Target flash sale offering extra 20% off everything with code SAVE20. Stacks with clearance prices on home, clothing, and electronics - ends midnight tonight.",

            aiGeneratedSummary: """
            **Actions:**
            • Copy code SAVE20 and shop by **midnight tonight**

            **Why:**
            Flash sale with extra 20% off already-reduced items.

            **Context:**
            • Stack with clearance for maximum savings
            • Valid on home, clothing, electronics
            """,
            body: """
            One Day Only - Extra 20% Off Everything!

            Hi there,

            Today is your lucky day! We're giving you an EXTRA 20% OFF on top of our already-reduced clearance prices.

            YOUR EXCLUSIVE CODE: SAVE20
            EXPIRES: Tonight at Midnight

            How It Works:
            1. Shop your favorite departments (no exclusions!)
            2. Add items to your cart
            3. Enter code SAVE20 at checkout
            4. Watch your savings add up!

            Stack Your Savings:
            This code works on EVERYTHING - including items already on sale. Find clearance deals and use SAVE20 for maximum savings!

            Popular Categories:
            🏠 Home & Decor - Refresh your space for fall
            👕 Clothing & Accessories - New arrivals + wardrobe essentials
            📱 Electronics - Tech gadgets and accessories
            🧸 Toys & Games - Early holiday shopping
            💄 Beauty & Personal Care - Premium brands

            Why Shop Target Today:
            ✓ Free shipping on orders $35+
            ✓ Free same-day delivery available in your area
            ✓ Easy returns within 90 days
            ✓ 5% off with Target RedCard

            Pro Tip: Combine SAVE20 with your Target Circle offers and RedCard for the ultimate savings stack!

            Don't wait - this flash sale ends at midnight tonight!

            SHOP NOW: target.com/deals

            Need help? Our team is standing by:
            • Chat: target.com/help
            • Call: 1-800-440-0680

            Happy shopping!

            The Target Team

            P.S. Check your Target Circle app for additional personalized offers!
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Copy Code",
            intent: "marketing.promo-code.offer",
            intentConfidence: 0.98,
            suggestedActions: [
                EmailAction(actionId: "copy_promo_code", displayName: "Copy Code", actionType: .inApp, isPrimary: true, priority: 1, context: ["promoCode": "SAVE20"]),
                EmailAction(actionId: "claim_deal", displayName: "Shop Now", actionType: .goTo, isPrimary: false, priority: 2, context: ["productUrl": "https://target.com/deals"])
            ],
            sender: SenderInfo(name: "Target", initial: "T", email: nil),
            kid: nil,
            company: nil,
            store: "Target",
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: 20,
            urgent: false,
            expiresIn: "Tonight",
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // complete_cart
        cards.append(EmailCard(
            id: "shop3",
            type: .ads,
            state: .unseen,
            priority: .medium,
            hpa: "Complete Cart",
            timeAgo: "4h ago",
            title: "Complete Your Order - 3 Items Waiting",
            summary: "Your REI cart has 3 items waiting: trail running shoes, insulated water bottle, and premium yoga mat for $156.97 total. Items are selling fast.",

            aiGeneratedSummary: """
            **Actions:**
            • Complete checkout for 3 items in cart

            **Why:**
            Your running shoes, water bottle, and yoga mat are waiting.

            **Context:**
            • Total: $156.97
            """,
            body: """
            Don't Leave Your Gear Behind!

            Hi there,

            We noticed you left some great items in your cart. Your outdoor essentials are still waiting for you - and they're going fast!

            Your Cart (3 Items):

            1. Women's Trail Runner Shoes - Size 8.5
               $89.99
               • Lightweight, breathable mesh
               • Superior grip for all terrains
               • Member favorite - 4.8/5 stars

            2. Insulated Water Bottle - 32oz
               $34.99
               • Keeps drinks cold 24+ hours
               • BPA-free stainless steel
               • Fits standard cup holders

            3. Premium Yoga Mat - 5mm
               $31.99
               • Non-slip textured surface
               • Extra cushioning for joints
               • Includes carrying strap

            Cart Total: $156.97

            REI Co-op Member Benefits:
            ✓ FREE shipping on orders $50+ (you qualify!)
            ✓ 10% annual dividend on full-price items
            ✓ Satisfaction guaranteed - return within 1 year

            These popular items won't last long! The trail runners especially are selling out fast in most sizes.

            Ready to complete your order? Your cart is saved and waiting.

            COMPLETE CHECKOUT: rei.com/cart

            Need Help Deciding?
            • Read customer reviews
            • Check our fit guides
            • Chat with our gear experts: 1-800-426-4840

            Not quite ready? No problem - your cart will be saved for 30 days.

            Get outside and enjoy!

            The REI Team

            P.S. Don't forget about your $20 dividend - it expires at the end of the month!
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Complete Cart",
            intent: "e-commerce.cart.abandoned",
            intentConfidence: 0.93,
            suggestedActions: [
                EmailAction(actionId: "complete_cart", displayName: "Complete Cart", actionType: .goTo, isPrimary: true, priority: 1, context: ["cartUrl": "https://rei.com/cart"]),
                EmailAction(actionId: "view_cart", displayName: "View Cart", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "REI", initial: "R", email: nil),
            kid: nil,
            company: nil,
            store: "REI",
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: 156.97,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // track_package
        cards.append(EmailCard(
            id: "shop4",
            type: .ads,
            state: .unseen,
            priority: .high,
            hpa: "Track Package",
            timeAgo: "30m ago",
            title: "Package Shipped - Arriving Tomorrow",
            summary: "Your Amazon order has shipped and is arriving tomorrow by 8 PM. Track with UPS using tracking number 1Z999AA10123456784.",

            aiGeneratedSummary: """
            **Actions:**
            • Track package arriving tomorrow by 8 PM

            **Why:**
            Your order has shipped and is on its way.

            **Context:**
            • Order #1234567
            • Carrier: UPS
            """,
            body: """
            Your Package is On the Way!

            Great news! Your Amazon order has been shipped and is arriving tomorrow.

            Delivery Details:
            • Estimated Arrival: Tomorrow by 8:00 PM
            • Carrier: UPS
            • Tracking Number: 1Z999AA10123456784
            • Order Number: #1234567

            What's Inside:
            Your package contains 2 items from your recent order.

            Tracking Your Package:
            Your package is currently in transit and on schedule for delivery. You can track its progress in real-time using the tracking number above.

            Delivery Options:
            • Leave at door (current selection)
            • Update delivery instructions
            • Request signature confirmation
            • Redirect to nearby UPS Access Point

            We'll send you another email when your package is out for delivery tomorrow. You can also track your delivery in real-time through the Amazon app.

            What to Do If You're Not Home:
            No worries! Based on your delivery preferences, the driver will leave your package in a safe location. You'll receive a photo confirmation once delivered.

            Need to Make Changes?
            You can update your delivery instructions or redirect your package until 8:00 PM tonight.

            TRACK PACKAGE: ups.com/track/1Z999AA10123456784
            VIEW ORDER: amazon.com/orders/1234567

            Questions About Your Order?
            Visit our Help Center or contact customer service 24/7.

            Thanks for shopping with Amazon!

            The Amazon Shipping Team

            Amazon.com
            Order Support: 1-888-280-4331
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Track Package",
            intent: "e-commerce.shipping.notification",
            intentConfidence: 1.0,
            suggestedActions: [
                EmailAction(actionId: "track_package", displayName: "Track Package", actionType: .inApp, isPrimary: true, priority: 1, context: ["url": "https://ups.com/track/1Z999AA10123456784", "trackingNumber": "1Z999AA10123456784", "carrier": "UPS", "orderNumber": "#1234567", "estimatedDelivery": "Tomorrow by 8 PM"]),
                EmailAction(actionId: "view_order", displayName: "View Order", actionType: .goTo, isPrimary: false, priority: 2, context: ["orderUrl": "https://amazon.com/orders/view/1234567"])
            ],
            sender: SenderInfo(name: "Amazon", initial: "A", email: nil),
            kid: nil,
            company: nil,
            store: "Amazon",
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // view_product
        cards.append(EmailCard(
            id: "shop5",
            type: .ads,
            state: .unseen,
            priority: .low,
            hpa: "View Product",
            timeAgo: "1d ago",
            title: "New Arrival: Patagonia Nano Puff Jacket",
            summary: "New Patagonia Nano Puff Jacket now available for $249. Lightweight insulated jacket perfect for fall layering with recycled materials and PrimaLoft insulation.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            New lightweight insulated jacket now available for fall.

            **Context:**
            • Price: $249
            • Perfect for layering in cool weather
            """,
            body: """
            New Arrival: The Iconic Nano Puff Jacket

            Fall is here, and so is your new favorite layer.

            Introducing the latest version of our legendary Nano Puff Jacket - now available in new seasonal colors. This versatile insulated jacket has been a customer favorite for years, and the 2025 edition is better than ever.

            Why the Nano Puff is a Must-Have:

            Lightweight Warmth
            At just 12 ounces, this jacket packs serious warmth without the bulk. PrimaLoft Gold Insulation Eco provides exceptional warmth-to-weight ratio and maintains warmth even when wet.

            Sustainable Construction
            • Shell fabric: 100% recycled polyester
            • Insulation: 60-g PrimaLoft Gold Insulation Eco (55% post-consumer recycled content)
            • Fair Trade Certified sewn

            Perfect for Fall Adventures:
            ✓ Cool morning hikes and trail runs
            ✓ Crisp evening campfires
            ✓ Everyday commuting and errands
            ✓ Layer under a shell for winter warmth

            Technical Features:
            • Horizontal quilting pattern stabilizes insulation
            • Zippered handwarmer pockets
            • Internal chest pocket doubles as stuffsack
            • Stretchy, adjustable hem
            • Women's specific fit with shaped silhouette

            Price: $249
            Available in 8 colors

            New Fall Colors Just Dropped:
            • Forest Green
            • Russet Orange
            • Navy Blue
            • Black (classic)
            • And more...

            Free Shipping & Returns
            Ironclad Guarantee - if you're not satisfied, return it anytime

            SHOP NANO PUFF: patagonia.com/nano-puff

            Join us in protecting the planet. 1% of all sales support environmental nonprofits.

            Patagonia
            Built to Last, Made to Explore
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: View Product",
            intent: "marketing.product.launch",
            intentConfidence: 0.88,
            suggestedActions: [
                EmailAction(actionId: "view_product", displayName: "View Product", actionType: .goTo, isPrimary: true, priority: 1, context: ["productUrl": "https://patagonia.com/nano-puff"]),
                EmailAction(actionId: "shop_now", displayName: "Shop Now", actionType: .goTo, isPrimary: false, priority: 2, context: ["productUrl": "https://patagonia.com/shop"])
            ],
            sender: SenderInfo(name: "Patagonia", initial: "P", email: nil),
            kid: nil,
            company: nil,
            store: "Patagonia",
            airline: nil,
            productImageUrl: "https://images.unsplash.com/photo-1551488831-00ddcb6c6bd3?w=400",
            brandName: "Patagonia",
            originalPrice: 249.00,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // schedule_purchase
        cards.append(EmailCard(
            id: "shop6",
            type: .ads,
            state: .unseen,
            priority: .high,
            hpa: "Buy on Oct 31",
            timeAgo: "2h ago",
            title: "James Jean - Sculpture and print duo",
            summary: "James Jean's Sun Tarot Nebula collection launches October 31 for one week only. Limited edition of 500 sets includes hand-painted sculpture and signed print.",

            aiGeneratedSummary: """
            **Actions:**
            • Schedule purchase for **October 31** launch

            **Why:**
            Limited edition Sun Tarot Nebula collection drops soon.

            **Context:**
            • One-week-only release
            • Sculpture and print duo
            """,

            body: """
            Exclusive Drop: James Jean - Sun Tarot Nebula Collection

            Mark Your Calendar - October 31st

            We're thrilled to announce an exclusive new release from visionary artist James Jean. The Sun Tarot Nebula collection launches on October 31st for ONE WEEK ONLY.

            About the Collection:

            "Sun Tarot Nebula" is a stunning limited edition set featuring both a sculptural element and a companion fine art print. This piece continues Jean's exploration of tarot symbolism through a cosmic lens, blending traditional iconography with otherworldly beauty.

            What's Included:
            • Hand-painted resin sculpture (8" x 6" x 4")
            • Matching signed and numbered fine art print (18" x 24")
            • Certificate of authenticity
            • Custom presentation box

            Edition Details:
            Limited to just 500 sets worldwide. Each sculpture is individually numbered and comes with a signed print from the edition of 500.

            The Artist:
            James Jean is a renowned Taiwanese-American visual artist known for his intricate narrative paintings and illustrations. His work has been exhibited in museums worldwide and collected by art enthusiasts globally.

            Release Information:
            • Launch Date: October 31st, 2025 at 12:00 PM EST
            • Available: One week only (or until sold out)
            • Edition Size: 500 pieces
            • Expected to sell out within 48 hours

            Why Collectors Love James Jean:
            ✓ Museum-quality craftsmanship
            ✓ Strong secondary market value
            ✓ Limited availability ensures exclusivity
            ✓ Stunning display pieces

            Set Your Reminder:
            Don't miss this exclusive drop! These limited editions typically sell out within hours of release.

            LEARN MORE: avantarte.com/releases/james-jean-2025

            Questions? Our art advisors are here to help: hello@avantarte.com

            Happy collecting,

            The Avant Arte Team
            Contemporary Art, Accessible to All
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Schedule Purchase",
            intent: "shopping.future_sale",
            intentConfidence: 1.0,
            suggestedActions: [
                EmailAction(
                    actionId: "schedule_purchase",
                    displayName: "Buy on Oct 31",
                    actionType: .inApp,
                    isPrimary: true,
                    priority: 1,
                    context: [
                        "saleDate": "31 October",
                        "productUrl": "https://avantarte.com/releases/james-jean-2025",
                        "productName": "James Jean - Sun Tarot Nebula"
                    ]
                ),
                EmailAction(actionId: "set_reminder", displayName: "Remind me on Oct 31", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Avant Arte", initial: "A", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: "https://images.unsplash.com/photo-1547826039-bfc35e0f1ea8?w=400",
            brandName: "James Jean",
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: true,
            expiresIn: "One week only",
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // Black Friday preview
        cards.append(EmailCard(
            id: "shop7",
            type: .ads,
            state: .unseen,
            priority: .low,
            hpa: "Preview Deals",
            timeAgo: "2d ago",
            title: "Black Friday Preview - Coming Nov 29",
            summary: "Best Buy's Black Friday sale preview showing deals across all tech categories. Massive savings on smartphones, laptops, TVs, and gaming starting November 29.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            Early access preview for upcoming Black Friday sale.

            **Context:**
            • Sale starts November 29
            • Biggest deals of the year
            """,
            body: """
            Get Ready: Black Friday is Almost Here!

            The biggest shopping event of the year is coming.

            Save the Date: November 29th

            Black Friday at Best Buy means unbeatable deals on everything tech. We're giving you an exclusive sneak peek at what's coming so you can plan your shopping strategy.

            What to Expect This Year:

            Massive Savings Across Every Category:
            📱 Smartphones & Tablets - Up to 40% off
            💻 Laptops & Computers - Save hundreds on top brands
            📺 TVs & Home Theater - Doorbuster pricing on 4K & 8K TVs
            🎮 Gaming - Consoles, games, and accessories
            🎧 Audio & Headphones - Premium sound for less
            📷 Cameras & Drones - Capture memories on sale
            🏠 Smart Home - Connected devices at great prices
            ⚡ Small Appliances - Kitchen and home essentials

            This Year's Features:
            ✓ Deals start online Thursday night (Nov 28) at 6 PM
            ✓ In-store doorbuster deals Friday morning
            ✓ Extended hours: Open at 5 AM Friday
            ✓ Free shipping on thousands of items
            ✓ Easy returns through January 14th

            Why Shop Black Friday at Best Buy:
            • Price match guarantee
            • Expert support and advice
            • Geek Squad services available
            • Buy online, pick up in store
            • Exclusive deals for My Best Buy members

            Get a Head Start:
            Download our Black Friday ad on November 20th to browse deals early and create your shopping wishlist.

            My Best Buy Members Get More:
            • Early access to select deals
            • Bonus points on purchases
            • Exclusive member-only pricing

            Not a member yet? Join free: bestbuy.com/membership

            PREVIEW DEALS: bestbuy.com/black-friday-preview

            Set your reminders - these deals won't last long!

            See you on Black Friday,

            The Best Buy Team
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Preview Deals",
            intent: "marketing.event.announcement",
            intentConfidence: 0.85,
            suggestedActions: [
                EmailAction(actionId: "view_deals", displayName: "Preview Deals", actionType: .goTo, isPrimary: true, priority: 1, context: ["dealsUrl": "https://bestbuy.com/black-friday-preview"]),
                EmailAction(actionId: "save_for_later", displayName: "Save for Later", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Best Buy", initial: "B", email: nil),
            kid: nil,
            company: nil,
            store: "Best Buy",
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // Amazon - AirPods Pro Deal
        cards.append(EmailCard(
            id: "shop8_amazon",
            type: .ads,
            state: .unseen,
            priority: .high,
            hpa: "Shop Deal",
            timeAgo: "2h ago",
            title: "AirPods Pro (2nd Gen) - Limited Offer",
            summary: "Prime exclusive deal on AirPods Pro 2nd Gen for $199 (save $50). Features 2X noise cancellation, USB-C charging, and free Prime delivery arriving tomorrow.",

            aiGeneratedSummary: """
            **Actions:**
            • Get AirPods Pro for **$199** (save $50, 20% off)

            **Why:**
            Prime member exclusive pricing on Apple's latest AirPods.

            **Context:**
            • Active Noise Cancellation, USB-C charging
            • Free Prime delivery
            """,
            body: """
            Prime Member Deal - Save $50 Today!

            Apple AirPods Pro (2nd Generation)

            Limited time Prime exclusive: Get the all-new AirPods Pro (2nd Generation) with USB-C charging for just $199 - that's $50 off the regular price!

            SALE PRICE: $199.00 (was $249.00)
            SAVINGS: $50.00 (20% off)
            PRIME DELIVERY: FREE - Arrives tomorrow

            What's New in 2nd Generation:
            ⭐ Up to 2X more Active Noise Cancellation
            ⭐ Adaptive Transparency mode
            ⭐ Personalized Spatial Audio with head tracking
            ⭐ USB-C charging case (works with iPhone 15)
            ⭐ Extra-small, small, medium, and large ear tips
            ⭐ Touch control for volume adjustment
            ⭐ Up to 6 hours listening time (30 hours with case)

            Perfect For:
            • Music lovers who demand the best audio
            • Commuters and frequent travelers
            • iPhone users (seamless pairing)
            • Fitness enthusiasts (sweat and water resistant)

            What's in the Box:
            ✓ AirPods Pro (2nd generation)
            ✓ USB-C charging case
            ✓ 4 sizes of silicone ear tips
            ✓ Lightning to USB-C cable
            ✓ Documentation

            Why Buy from Amazon:
            • Fulfilled by Amazon - 100% authentic
            • Free Prime delivery
            • Easy returns within 30 days
            • 1-year Apple warranty included

            This deal won't last - grab yours while supplies last!

            SHOP NOW: amazon.com/airpods-pro

            Amazon Electronics
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Shop Amazon Deal",
            threadLength: 1,
            intent: "e-commerce.promotional.deal",
            intentConfidence: 0.96,
            suggestedActions: [
                EmailAction(actionId: "claim_deal", displayName: "Shop Deal", actionType: .goTo, isPrimary: true, priority: 1, context: ["productUrl": "https://www.amazon.com/Apple-AirPods-Pro-2nd-Generation/dp/B0CHWRXH8B"]),
                EmailAction(actionId: "save_deal", displayName: "Save for Later", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Amazon", initial: "A", email: nil),
            kid: nil,
            company: nil,
            store: "Amazon",
            airline: nil,
            productImageUrl: "https://images.unsplash.com/photo-1606841837239-c5a1a4a07af7?w=400",
            brandName: "Apple",
            originalPrice: 249.00,
            salePrice: 199.00,
            discount: 20,
            urgent: true,
            expiresIn: "12 hours",
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // Target - AirPods Pro Deal
        cards.append(EmailCard(
            id: "shop9_target",
            type: .ads,
            state: .unseen,
            priority: .high,
            hpa: "Add to Cart",
            timeAgo: "4h ago",
            title: "Target Deal: AirPods Pro 2nd Gen",
            summary: "Target Circle Week deal on AirPods Pro for $209.99 plus $10 gift card. Order pickup ready in 2 hours or same-day delivery - ends tonight at midnight.",

            aiGeneratedSummary: """
            **Actions:**
            • Claim Circle offer for **$209.99** (16% off + $10 gift card)

            **Why:**
            Target Circle exclusive with bonus gift card.

            **Context:**
            • Save $40 + get $10 Target gift card
            • Order pickup or same-day delivery available
            """,
            body: """
            Circle Week Deal - Ends Tonight!

            Apple AirPods Pro (2nd Generation)

            Target Circle members save big on Apple's latest AirPods Pro! Get them for $209.99 PLUS receive a $10 Target gift card with purchase.

            SALE PRICE: $209.99 (was $249.99)
            BONUS: $10 Target gift card
            TOTAL SAVINGS: $50+ value
            CIRCLE WEEK: Deal ends tonight at midnight

            Premium Features:
            ⭐ Active Noise Cancellation - block out the world
            ⭐ Adaptive Audio - automatically adjusts to your environment
            ⭐ Personalized Spatial Audio with dynamic head tracking
            ⭐ Transparency mode - hear what you need to
            ⭐ USB-C charging case (compatible with iPhone 15)
            ⭐ Sweat and water resistant (IPX4)

            Target Benefits:
            • Order Pickup - ready in 2 hours
            • Same Day Delivery with Shipt
            • Free shipping on orders $35+
            • Extended holiday returns through January 25
            • 5% off with Target RedCard

            What Customers Love:
            ⭐⭐⭐⭐⭐ 4.8/5 stars (12,450 reviews)
            "Best earbuds I've ever owned!" - Sarah M.
            "The noise cancellation is incredible" - Mike T.
            "Worth every penny for the sound quality" - Jessica R.

            In Stock Now:
            Available for immediate pickup at your local Target or get same-day delivery.

            Don't miss out - this Circle Week deal ends at midnight!

            ADD TO CART: target.com/airpods-pro

            Target
            Expect More. Pay Less.
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Add to Cart",
            threadLength: 1,
            intent: "e-commerce.promotional.deal",
            intentConfidence: 0.95,
            suggestedActions: [
                EmailAction(actionId: "claim_deal", displayName: "Add to Cart", actionType: .goTo, isPrimary: true, priority: 1, context: ["productUrl": "https://www.target.com/p/airpods-pro-2nd-generation/-/A-85978622"]),
                EmailAction(actionId: "find_store", displayName: "Find in Store", actionType: .goTo, isPrimary: false, priority: 2, context: ["storeUrl": "https://www.target.com/store-locator"])
            ],
            sender: SenderInfo(name: "Target", initial: "T", email: nil),
            kid: nil,
            company: nil,
            store: "Target",
            airline: nil,
            productImageUrl: "https://images.unsplash.com/photo-1606841837239-c5a1a4a07af7?w=400",
            brandName: "Apple",
            originalPrice: 249.99,
            salePrice: 209.99,
            discount: 16,
            urgent: true,
            expiresIn: "8 hours",
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // Walmart - AirPods Pro Deal
        cards.append(EmailCard(
            id: "shop10_walmart",
            type: .ads,
            state: .unseen,
            priority: .medium,
            hpa: "Shop Now",
            timeAgo: "6h ago",
            title: "Rollback: AirPods Pro 2nd Gen $219",
            summary: "Walmart Rollback on AirPods Pro 2nd Gen for $219 (save $30). Free 2-day shipping or pickup today with advanced noise cancellation and USB-C charging.",

            aiGeneratedSummary: """
            **Actions:**
            • Get AirPods Pro for **$219** (save $30)

            **Why:**
            Walmart Rollback pricing with free shipping.

            **Context:**
            • Free 2-day shipping or pickup today
            • Walmart+ members get free delivery from store
            """,
            body: """
            Rollback Alert - Save $30!

            Apple AirPods Pro (2nd Generation) with MagSafe Case (USB-C)

            We've rolled back the price on Apple's newest AirPods Pro! Get premium wireless earbuds with advanced noise cancellation for just $219.

            ROLLBACK PRICE: $219.00 (was $249.00)
            SAVINGS: $30.00
            FREE 2-DAY SHIPPING or Pickup Today

            Advanced Features:
            ⭐ Up to 2x more Active Noise Cancellation
            ⭐ Transparency mode - stay aware of surroundings
            ⭐ Adaptive Audio - seamless listening experience
            ⭐ Personalized Spatial Audio
            ⭐ USB-C charging (works with your iPhone 15)
            ⭐ Up to 6 hours listening time
            ⭐ Up to 30 hours total with charging case
            ⭐ Sweat and water resistant

            Why Shop Walmart:
            • Everyday Low Prices
            • Free pickup today at your local store
            • Free 2-day shipping
            • Walmart+ members: Free delivery from store
            • Easy returns - 90 days
            • Protection plans available

            Customer Reviews:
            ⭐⭐⭐⭐⭐ 4.7/5 (8,234 reviews)
            "Amazing sound quality and noise cancellation!"
            "Best investment for daily commute"
            "The USB-C case is a game changer"

            Shipping & Pickup Options:
            • FREE Pickup Today - Check local availability
            • FREE 2-Day Shipping
            • FREE Delivery from Store (Walmart+ members)
            • Express Delivery available

            In Stock Online and In Stores!

            SHOP NOW: walmart.com/airpods-pro

            Walmart
            Save Money. Live Better.
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Shop Walmart",
            threadLength: 1,
            intent: "e-commerce.promotional.deal",
            intentConfidence: 0.94,
            suggestedActions: [
                EmailAction(actionId: "claim_deal", displayName: "Shop Now", actionType: .goTo, isPrimary: true, priority: 1, context: ["productUrl": "https://www.walmart.com/ip/Apple-AirPods-Pro-2nd-Generation-with-MagSafe-Case-USB-C/1752657021"]),
                EmailAction(actionId: "check_inventory", displayName: "Check Store", actionType: .goTo, isPrimary: false, priority: 2, context: ["storeUrl": "https://www.walmart.com/store-finder"])
            ],
            sender: SenderInfo(name: "Walmart", initial: "W", email: nil),
            kid: nil,
            company: nil,
            store: "Walmart",
            airline: nil,
            productImageUrl: "https://images.unsplash.com/photo-1606841837239-c5a1a4a07af7?w=400",
            brandName: "Apple",
            originalPrice: 249.00,
            salePrice: 219.00,
            discount: 12,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // MARK: - BILLING (4 actions)

        // pay_invoice
        cards.append(EmailCard(
            id: "bill1",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "Pay Invoice",
            timeAgo: "1h ago",
            title: "Invoice #INV-2025-1234 Due Oct 30",
            summary: "Acme Corp invoice for $599 due October 30 (3 days away). Covers 20 hours of strategic planning and implementation services - late fees apply after due date.",

            aiGeneratedSummary: """
            **Actions:**
            • Pay $599 invoice by **October 30** (3 days)

            **Why:**
            October consulting services invoice is due.

            **Context:**
            • 20 hours of strategic planning and implementation
            • Late fees apply after due date
            """,

            body: """
            INVOICE

            Acme Corp Professional Services
            123 Business Street, Suite 400
            San Francisco, CA 94105
            billing@acmecorp.com | (415) 555-0199

            BILL TO:
            Sarah Chen
            456 Market Street
            San Francisco, CA 94103

            Invoice Number: INV-2025-1234
            Invoice Date: October 23, 2025
            Due Date: October 30, 2025
            Payment Terms: Net 7 Days

            SERVICES PROVIDED - OCTOBER 2025

            Description                                    Hours    Rate      Amount
            ─────────────────────────────────────────────────────────────────────
            Strategic Planning Session                     4.0      $65/hr    $260.00
            Implementation Consulting                      10.0     $65/hr    $650.00
            Technical Documentation                        4.0      $65/hr    $260.00
            Follow-up Support & Review                     2.0      $65/hr    $130.00
            ─────────────────────────────────────────────────────────────────────

            Subtotal:                                                          $1,300.00
            Professional Services Discount (20%):                              -$390.00
            Sales Tax (8.5%):                                                  $77.35
            ─────────────────────────────────────────────────────────────────────

            TOTAL DUE:                                                         $599.00

            PAYMENT INFORMATION:

            Please remit payment by October 30, 2025 to avoid late fees.

            Payment Methods Accepted:
            • Online: pay.acme.com/INV-2025-1234
            • ACH Transfer: Account details available upon request
            • Credit Card: Visa, Mastercard, American Express
            • Check: Payable to "Acme Corp Professional Services"

            Late Payment Policy:
            A late fee of 1.5% per month (18% APR) will be applied to any balance remaining after the due date.

            Questions about this invoice? Contact our billing department:
            📧 billing@acmecorp.com
            📞 (415) 555-0199

            Thank you for your business!

            Acme Corp Professional Services
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Pay Invoice",
            threadLength: 5,
            intent: "billing.invoice.due",
            intentConfidence: 1.0,
            suggestedActions: [
                EmailAction(actionId: "pay_invoice", displayName: "Pay Invoice", actionType: .inApp, isPrimary: true, priority: 1, context: ["invoiceId": "INV-2025-1234", "amount": "$599.00", "merchant": "Acme Corp", "dueDate": "Oct 30", "invoiceUrl": "https://pay.acme.com/INV-2025-1234"]),
                EmailAction(actionId: "view_invoice", displayName: "View Details", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "download_receipt", displayName: "Download PDF", actionType: .inApp, isPrimary: false, priority: 3)
            ],
            sender: nil,
            kid: nil,
            company: CompanyInfo(name: "Acme Corp", initials: "AC"),
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: 599.00,
            paymentDescription: "Professional Services Invoice",
            value: nil,
            probability: nil,
            score: nil
        ))

        // download_receipt
        cards.append(EmailCard(
            id: "bill2",
            type: .mail,
            state: .unseen,
            priority: .medium,
            hpa: "Download Receipt",
            timeAgo: "2h ago",
            title: "Payment Received - $1,250.00",
            summary: "Stripe payment of $1,250 successfully processed on October 23. Account balance now $0 - receipt available for download and tax records.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            Payment of $1,250 successfully processed for Invoice #INV-2025-0987.

            **Context:**
            • Transaction date: October 23, 2025
            • Balance now $0
            • Receipt attached for records
            """,
            body: """
            Payment Confirmation

            Thank you for your payment!

            Dear Sarah Chen,

            This email confirms that we have successfully received and processed your payment.

            PAYMENT DETAILS

            Payment Amount: $1,250.00
            Payment Method: Visa ending in 4242
            Transaction ID: ch_3Nqy8k2eZvKYlo2C1a2b3c4d
            Transaction Date: October 23, 2025 at 2:34 PM PST
            Status: PAID ✓

            INVOICE INFORMATION

            Invoice Number: INV-2025-0987
            Invoice Date: October 15, 2025
            Original Amount Due: $1,250.00
            Amount Paid: $1,250.00
            Balance Remaining: $0.00

            Your account is now current. Thank you for your prompt payment!

            RECEIPT INFORMATION

            Your receipt has been generated and is available for download. This receipt can be used for:
            • Accounting and bookkeeping records
            • Tax documentation
            • Expense reimbursement
            • Business records

            Download Your Receipt: stripe.com/receipts/INV-2025-0987

            NEXT STEPS

            ✓ Your payment has been processed
            ✓ Receipt is available for download
            ✓ Account balance is $0.00
            ✓ No further action required

            Questions or Concerns?

            If you have any questions about this payment or need assistance, our support team is here to help:

            • Email: support@stripe.com
            • Phone: 1-888-926-2289 (24/7 support)
            • Help Center: stripe.com/support

            Thank you for being a valued customer. We appreciate your business!

            Best regards,

            Stripe Billing Team
            payments@stripe.com

            ---
            Stripe, Inc. | 354 Oyster Point Blvd, South San Francisco, CA 94080
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Download Receipt",
            intent: "billing.payment.confirmation",
            intentConfidence: 0.98,
            suggestedActions: [
                EmailAction(actionId: "download_receipt", displayName: "Download Receipt", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "view_details", displayName: "View Details", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: nil,
            kid: nil,
            company: CompanyInfo(name: "Stripe", initials: "S"),
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: 1250.00,
            paymentDescription: "Payment Received",
            value: nil,
            probability: nil,
            score: nil
        ))

        // view_invoice
        cards.append(EmailCard(
            id: "bill3",
            type: .mail,
            state: .unseen,
            priority: .medium,
            hpa: "View Invoice",
            timeAgo: "1d ago",
            title: "New Invoice Available - $299/month",
            summary: "Adobe Creative Cloud monthly subscription invoice for $299 is now available. Payment will be processed automatically from your saved payment method.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            Monthly subscription invoice is ready to view.

            **Context:**
            • Amount: $299/month
            • Adobe subscription
            """,
            body: """
            Your Adobe Creative Cloud Invoice is Ready

            Hello,

            Your monthly Adobe Creative Cloud invoice for November 2025 is now available for viewing.

            INVOICE SUMMARY

            Account: sarah.chen@email.com
            Invoice Number: ADO-112025-8492
            Billing Period: November 1-30, 2025
            Invoice Date: November 1, 2025
            Amount: $299.00

            SUBSCRIPTION DETAILS

            Plan: Creative Cloud All Apps - Individual
            License Type: Single User License

            Includes Access To:
            ✓ Photoshop, Lightroom, Illustrator, InDesign
            ✓ Premiere Pro, After Effects, Audition
            ✓ XD, Animate, Dreamweaver, and 15+ more apps
            ✓ 100GB cloud storage
            ✓ Adobe Fonts complete library
            ✓ Adobe Portfolio
            ✓ Adobe Express premium features

            PAYMENT INFORMATION

            Payment Method: Visa ending in 8765
            Payment Status: Auto-pay scheduled for November 5, 2025
            Next Billing Date: December 1, 2025

            Your payment will be automatically processed on November 5th. No action is required unless you need to update your payment method.

            View Full Invoice: adobe.com/account/invoice/ADO-112025-8492
            Download PDF: adobe.com/account/download-invoice/ADO-112025-8492

            MANAGE YOUR SUBSCRIPTION

            Need to make changes to your plan?
            • Update payment method
            • Change plan or add seats
            • View billing history
            • Update account details

            Manage Subscription: adobe.com/account/manage

            NEED HELP?

            Our support team is available 24/7:
            • Chat: adobe.com/support
            • Phone: 1-800-833-6687
            • Help Center: helpx.adobe.com

            Thank you for being an Adobe Creative Cloud member!

            The Adobe Team
            billing@adobe.com

            Adobe Inc. | 345 Park Avenue, San Jose, CA 95110
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: View Invoice",
            intent: "billing.invoice.available",
            intentConfidence: 0.95,
            suggestedActions: [
                EmailAction(actionId: "view_invoice", displayName: "View Invoice", actionType: .goTo, isPrimary: true, priority: 1, context: ["invoiceUrl": "https://billing.com/view-invoice"]),
                EmailAction(actionId: "download_receipt", displayName: "Download PDF", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: nil,
            kid: nil,
            company: CompanyInfo(name: "Adobe", initials: "A"),
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: 299.00,
            paymentDescription: "Monthly Subscription",
            value: nil,
            probability: nil,
            score: nil
        ))

        // manage_subscription
        cards.append(EmailCard(
            id: "bill4",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "Manage Subscription",
            timeAgo: "3h ago",
            title: "Subscription Renewal Tomorrow",
            summary: "GitHub Team annual subscription auto-renews tomorrow for $999. Includes unlimited repos, Actions, and advanced security - update payment or cancel if needed.",

            aiGeneratedSummary: """
            **Actions:**
            • Review subscription renewing **tomorrow** for $999

            **Why:**
            Annual GitHub plan auto-renews in 1 day.

            **Context:**
            • Amount: $999/year
            • Update payment method or cancel if needed
            """,
            body: """
            Your GitHub Subscription Renews Tomorrow

            Important: Action may be required

            Hello Sarah,

            This is a friendly reminder that your GitHub annual subscription will automatically renew tomorrow, October 26, 2025.

            RENEWAL DETAILS

            Plan: GitHub Team (Annual)
            Renewal Date: October 26, 2025
            Renewal Amount: $999.00
            Payment Method: Mastercard ending in 1234

            What You'll Continue to Enjoy:

            Team Collaboration Features:
            ✓ Unlimited public and private repositories
            ✓ Team access controls and permissions
            ✓ Protected branches and required reviews
            ✓ Code owners
            ✓ Draft pull requests
            ✓ Team discussions

            Developer Tools:
            ✓ GitHub Actions (3,000 minutes/month)
            ✓ GitHub Packages (2GB storage)
            ✓ GitHub Pages
            ✓ Wikis for documentation
            ✓ Multiple issue assignees
            ✓ Multiple pull request reviewers

            Support & Security:
            ✓ 24/7 community support
            ✓ Advanced security features
            ✓ Dependabot alerts
            ✓ Code scanning

            TAKE ACTION (Optional)

            No action is required if you wish to continue your subscription. However, if you need to make changes, please do so before tomorrow:

            • Update your payment method
            • Change your plan (upgrade/downgrade)
            • Cancel your subscription

            Manage Subscription: github.com/settings/billing

            QUESTIONS ABOUT YOUR RENEWAL?

            • Why am I being charged? Your annual subscription term is ending and will auto-renew
            • Can I get a refund? Yes, within 30 days of renewal
            • How do I cancel? Visit your billing settings before the renewal date
            • Need to update payment info? Update in your account settings

            We're Here to Help:
            • Support: support.github.com
            • Billing Questions: github.com/contact
            • Documentation: docs.github.com/billing

            Thank you for being a valued GitHub customer! We're committed to helping your team build better software together.

            The GitHub Team
            support@github.com

            GitHub, Inc. | 88 Colin P Kelly Jr St, San Francisco, CA 94107
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Manage Subscription",
            intent: "billing.subscription.renewal",
            intentConfidence: 0.97,
            suggestedActions: [
                EmailAction(actionId: "manage_subscription", displayName: "Manage Subscription", actionType: .goTo, isPrimary: true, priority: 1, context: ["subscriptionUrl": "https://account.com/subscription"]),
                EmailAction(actionId: "update_payment", displayName: "Update Payment", actionType: .goTo, isPrimary: false, priority: 2, context: ["paymentUrl": "https://account.com/payment-methods"])
            ],
            sender: nil,
            kid: nil,
            company: CompanyInfo(name: "GitHub", initials: "G"),
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: 999.00,
            paymentDescription: "Annual Subscription Renewal",
            value: nil,
            probability: nil,
            score: nil
        ))

        // cancel_subscription (Hulu)
        cards.append(EmailCard(
            id: "bill5",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "Cancel Subscription",
            timeAgo: "1d ago",
            title: "Hulu Subscription Renews in 3 Days",
            summary: "Hulu (No Ads) subscription auto-renews October 29 for $17.99/month. Cancel before then to avoid charge - access continues until end of current period.",

            aiGeneratedSummary: """
            **Actions:**
            • Cancel subscription before **October 29** to avoid charge

            **Why:**
            Hulu (No Ads) plan auto-renews in 3 days for $17.99/month.

            **Context:**
            • Monthly billing cycle, easy cancellation
            • Access continues until end of current period
            """,

            body: """
            Your Hulu Subscription Renews Soon

            Hi there,

            This is a friendly reminder that your Hulu (No Ads) subscription will automatically renew in 3 days.

            SUBSCRIPTION DETAILS

            Plan: Hulu (No Ads)
            Next Billing Date: October 29, 2025
            Amount: $17.99/month
            Payment Method: Visa ending in 4321

            What's Included:
            ✓ Unlimited streaming of Hulu Originals
            ✓ Full seasons of exclusive series
            ✓ Hit movies, groundbreaking documentaries
            ✓ Kids content and family-friendly programming
            ✓ Streaming on 2 screens simultaneously
            ✓ Download & watch offline on mobile
            ✓ No ads during shows or movies

            Currently Watching:
            • The Bear (Season 3)
            • Only Murders in the Building
            • The Handmaid's Tale
            • Abbott Elementary

            MANAGE YOUR SUBSCRIPTION

            If you'd like to make changes before your renewal:

            • Cancel your subscription (access continues until Oct 29)
            • Switch to Hulu (With Ads) - Save $10/month
            • Add Disney+ Bundle - Save 25%
            • Update payment method
            • Manage profiles and parental controls

            Manage Account: hulu.com/account

            WHY USERS LOVE HULU

            "Best streaming service for keeping up with current TV shows" - TechRadar
            "Hulu's original content rivals Netflix and HBO Max" - The Verge

            New This Month:
            • The Old Man (Season 2 premiere)
            • Reasonable Doubt (New episodes weekly)
            • Animayhem (Hulu Original)

            QUESTIONS?

            • Will I lose access if I cancel? No, you can stream until Oct 29
            • Can I resubscribe later? Yes, anytime at regular price
            • How do I cancel? Visit hulu.com/account/cancel
            • Want to pause instead? We offer a hold option for up to 12 weeks

            Need help? Visit our Help Center or chat with us 24/7.

            Thanks for streaming with Hulu!
            The Hulu Team

            Hulu, LLC | 2500 Broadway, Santa Monica, CA 90404
            Manage email preferences | Unsubscribe from promotional emails
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Cancel Subscription",
            intent: "billing.subscription.renewal",
            intentConfidence: 0.96,
            suggestedActions: [
                EmailAction(actionId: "cancel_subscription", displayName: "Cancel Subscription", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "manage_subscription", displayName: "Manage Subscription", actionType: .goTo, isPrimary: false, priority: 2, context: ["subscriptionUrl": "https://hulu.com/account"]),
                EmailAction(actionId: "update_payment", displayName: "Update Payment", actionType: .goTo, isPrimary: false, priority: 3, context: ["paymentUrl": "https://hulu.com/account/payment"]),
                EmailAction(actionId: "save_for_later", displayName: "Save for Later", actionType: .inApp, isPrimary: false, priority: 4)
            ],
            sender: SenderInfo(name: "Hulu", initial: "H", email: nil),
            kid: nil,
            company: CompanyInfo(name: "Hulu", initials: "H"),
            store: nil,
            airline: nil,
            productImageUrl: "https://images.unsplash.com/photo-1522869635100-9f4c5e86aa37?w=400",
            brandName: "Hulu",
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: true,
            expiresIn: "3 days",
            requiresSignature: nil,
            paymentAmount: 17.99,
            paymentDescription: "Monthly Subscription",
            value: nil,
            probability: nil,
            score: nil
        ))

        // MARK: - SALES (2 actions)

        // schedule_meeting
        cards.append(EmailCard(
            id: "sales1",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "Schedule Meeting",
            timeAgo: "2h ago",
            title: "Product Demo Request - Acme Solutions",
            summary: "Acme Solutions requesting product demo this week for 50-75 licenses. High-value lead worth $50k with lead score of 85 - evaluating solutions this month.",

            aiGeneratedSummary: """
            **Actions:**
            • Schedule 30-min demo this week

            **Why:**
            Acme Solutions wants to see platform demo.

            **Context:**
            • Potential value: $50k
            • Lead score: 85
            """,

            body: """
            Product Demo Request from Acme Solutions

            Hi Sarah,

            Great news! We have a high-value inbound lead requesting a product demonstration.

            LEAD INFORMATION

            Company: Acme Solutions
            Contact: John Smith
            Title: VP of Operations
            Email: john@acme.com
            Phone: (555) 123-4567

            Company Size: 250-500 employees
            Industry: Enterprise Software
            Location: Austin, TX

            LEAD SCORE: 85/100 (Hot Lead!)

            Scoring Breakdown:
            ✓ Company size matches ICP (25 points)
            ✓ Budget authority confirmed (20 points)
            ✓ Active evaluation timeline (20 points)
            ✓ Direct inbound request (15 points)
            ✓ Multiple stakeholders interested (5 points)

            OPPORTUNITY DETAILS

            Estimated Deal Value: $50,000 ARR
            Contract Type: Annual subscription
            Potential Users: 50-75 licenses
            Timeline: Evaluating solutions this month
            Competition: Also considering 2 competitors

            REQUEST DETAILS

            John Smith submitted a demo request through our website yesterday. He mentioned:

            "We're currently evaluating platforms to streamline our project management workflow. I'd like to schedule a 30-minute demo this week to see how your platform handles team collaboration and reporting. We're looking to make a decision by end of month."

            RECOMMENDED NEXT STEPS

            1. Schedule demo for this week (they're on a tight timeline!)
            2. Prepare custom demo focusing on:
               - Team collaboration features
               - Advanced reporting capabilities
               - Enterprise security & compliance
            3. Send pre-demo questionnaire to understand pain points
            4. Include ROI calculator in follow-up

            Their Availability:
            • Tuesday 2-4 PM CST
            • Wednesday 10 AM-12 PM CST
            • Thursday 1-3 PM CST

            SCHEDULE MEETING: calendly.com/sarah-chen/demo

            This is a high-priority opportunity with strong buying signals. Let's move quickly to get on their calendar before competitors do!

            Questions? Reply to this email or ping me on Slack.

            Best,

            Sales Operations Team
            sales@yourcompany.com
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Schedule Meeting",
            intent: "sales.demo.request",
            intentConfidence: 0.96,
            suggestedActions: [
                EmailAction(actionId: "schedule_meeting", displayName: "Schedule Meeting", actionType: .inApp, isPrimary: true, priority: 1, context: ["proposedTimes": "This week"]),
                EmailAction(actionId: "reply", displayName: "Reply", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "John Smith", initial: "J", email: "john@acme.com"),
            kid: nil,
            company: CompanyInfo(name: "Acme Solutions", initials: "AS"),
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: "$50k",
            probability: 70,
            score: 85
        ))

        // view_proposal
        cards.append(EmailCard(
            id: "sales2",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "View Proposal",
            timeAgo: "5h ago",
            title: "Enterprise Proposal - $125k/year",
            summary: "TechCorp enterprise proposal for 500 users at $125k/year with 3-year contract. Includes SSO, dedicated support, and on-site training - 60% win probability.",

            aiGeneratedSummary: """
            **Actions:**
            • Review enterprise proposal for 500-user team

            **Why:**
            TechCorp sent promised enterprise pricing proposal.

            **Context:**
            • Deal value: $125k/year
            • Win probability: 60%
            """,
            body: """
            Enterprise Proposal: TechCorp - 500 User Team

            Hi Sarah,

            As promised, I'm sending over our enterprise proposal for TechCorp's team collaboration platform needs.

            PROPOSAL OVERVIEW

            Company: TechCorp
            Deal Size: $125,000/year
            Contract Term: 3-year agreement
            User Count: 500 licenses
            Win Probability: 60%
            Decision Maker: Candace Johnson, CTO

            PROPOSED SOLUTION

            Enterprise Plan - 500 Users
            Annual Cost: $125,000 ($250/user/year)

            What's Included:
            ✓ Unlimited projects and workspaces
            ✓ Advanced security & compliance (SOC 2, GDPR, HIPAA)
            ✓ Single Sign-On (SSO) with SAML 2.0
            ✓ Custom domain and branding
            ✓ Priority 24/7 phone & email support
            ✓ Dedicated Customer Success Manager
            ✓ Quarterly business reviews
            ✓ Advanced analytics & reporting
            ✓ API access with higher rate limits
            ✓ Custom integrations assistance
            ✓ On-site training for 3 sessions
            ✓ 99.9% uptime SLA

            PRICING BREAKDOWN

            Year 1: $125,000
            Year 2: $125,000 (locked rate)
            Year 3: $125,000 (locked rate)

            3-Year Total: $375,000
            Payment Terms: Annual billing (quarterly available upon request)

            SAVINGS HIGHLIGHTS

            Compared to Standard Pricing:
            • Regular price: $299/user/year = $149,500
            • Enterprise discount: 16% savings
            • First-year savings: $24,500

            Additional Value:
            • Locked pricing for 3 years (no annual increases)
            • Free premium support ($15,000 value)
            • Free onboarding & training ($10,000 value)
            • Total value: $49,500 in year one

            IMPLEMENTATION TIMELINE

            Week 1-2: Account setup & SSO configuration
            Week 3-4: Data migration & integration setup
            Week 5-6: Team training sessions (3 sessions)
            Week 7: Go-live & optimization
            Week 8+: Ongoing support & adoption monitoring

            NEXT STEPS

            I'd love to schedule a follow-up call to walk through the proposal and answer any questions:
            • Review pricing and terms
            • Discuss implementation timeline
            • Address technical requirements
            • Customize any aspects of the proposal

            VIEW FULL PROPOSAL: proposals.com/view/abc123

            The proposal includes:
            • Detailed feature comparison
            • ROI calculator
            • Case studies from similar companies
            • Security & compliance documentation
            • References from enterprise customers

            I'm available this week for a call. Does Thursday at 2 PM work for you?

            Looking forward to partnering with TechCorp!

            Best regards,

            Candace Johnson
            Enterprise Sales Executive
            candace@yourcompany.com
            (555) 789-0123
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: View Proposal",
            intent: "sales.proposal.sent",
            intentConfidence: 0.99,
            suggestedActions: [
                EmailAction(actionId: "view_proposal", displayName: "View Proposal", actionType: .goTo, isPrimary: true, priority: 1, context: ["proposalUrl": "https://proposals.com/view/abc123"]),
                EmailAction(actionId: "schedule_meeting", displayName: "Schedule Follow-up", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Candace Johnson", initial: "C", email: "candace@techcorp.com"),
            kid: nil,
            company: CompanyInfo(name: "TechCorp", initials: "TC"),
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: "$125k",
            probability: 60,
            score: 78
        ))

        // MARK: - PROJECT (4 actions)

        // join_meeting
        cards.append(EmailCard(
            id: "proj1",
            type: .mail,
            state: .unseen,
            priority: .critical,
            hpa: "Join Meeting",
            timeAgo: "5m ago",
            title: "Sprint Planning - Starting in 10 min",
            summary: "Q4 sprint planning meeting starting in 10 minutes at 10:00 AM PST. Join Zoom for 90-minute session covering velocity, backlog refinement, and sprint commitment.",

            aiGeneratedSummary: """
            **Actions:**
            • Join Q4 sprint planning meeting **now** (starting in 10 min)

            **Why:**
            Sprint planning meeting about to start.

            **Context:**
            • Zoom link available
            • Agenda: Q4 planning
            """,
            body: """
            URGENT: Sprint Planning Meeting Starting in 10 Minutes

            Hi Team,

            This is your 10-minute reminder that our Q4 Sprint Planning meeting is about to begin!

            MEETING DETAILS

            Topic: Q4 Sprint Planning - November Sprint
            Start Time: Today at 10:00 AM PST
            Duration: 90 minutes
            Join: zoom.us/j/123456789

            Meeting ID: 123 456 789
            Passcode: sprint2024

            AGENDA (90 minutes)

            1. Sprint Review (15 min)
               - Review completed stories from last sprint
               - Demo key features shipped

            2. Velocity & Capacity Planning (15 min)
               - Review team velocity from last 3 sprints
               - Discuss team availability for upcoming sprint
               - Address any capacity concerns

            3. Backlog Refinement (30 min)
               - Review top priority items
               - Clarify requirements and acceptance criteria
               - Size stories using planning poker

            4. Sprint Goal & Commitment (20 min)
               - Define sprint goal
               - Select stories for sprint
               - Confirm team commitment

            5. Task Breakdown & Assignment (10 min)
               - Break stories into technical tasks
               - Initial task assignments

            WHO SHOULD ATTEND

            Required:
            ✓ All engineering team members
            ✓ Product Manager
            ✓ Scrum Master
            ✓ UX Designer

            Optional:
            • QA Lead (for testing discussion)
            • Engineering Manager (for capacity questions)

            PREPARATION REMINDERS

            Please make sure you've:
            - Reviewed the prioritized backlog in Jira
            - Completed any pre-refinement tickets
            - Prepared questions about unclear requirements
            - Updated your availability for the sprint

            JOIN MEETING NOW: zoom.us/j/123456789

            Can't make it? Please let me know ASAP so we can reschedule or proceed without you.

            See you in 10 minutes!

            Project Manager
            Engineering Team
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Join Meeting",
            intent: "project.meeting.reminder",
            intentConfidence: 1.0,
            suggestedActions: [
                EmailAction(actionId: "join_meeting", displayName: "Join Meeting", actionType: .goTo, isPrimary: true, priority: 1, context: ["meetingUrl": "https://zoom.us/j/123456789"]),
                EmailAction(actionId: "view_agenda", displayName: "View Agenda", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Project Manager", initial: "P", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // view_task
        cards.append(EmailCard(
            id: "proj2",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "View Task",
            timeAgo: "2h ago",
            title: "Task Assigned: API Integration",
            summary: "New Jira task PROJ-123 assigned for Stripe payment gateway integration. Due Friday with 16-hour estimate - supports credit cards, Apple Pay, and Google Pay.",

            aiGeneratedSummary: """
            **Actions:**
            • Complete payment gateway integration by **end of week**

            **Why:**
            New task assigned for payment API integration.

            **Context:**
            • Project: PROJ-123
            • Deadline: Friday
            """,
            body: """
            New Task Assigned: Payment Gateway Integration

            Hi Sarah,

            You've been assigned a new task in Jira that requires your attention.

            TASK DETAILS

            Task: PROJ-123 - Payment Gateway Integration
            Project: E-Commerce Platform Upgrade
            Priority: High
            Status: To Do
            Due Date: Friday, October 27, 2025
            Estimated Effort: 16 hours (2 days)

            DESCRIPTION

            Integrate Stripe payment gateway into the checkout flow to support credit card and digital wallet payments.

            Requirements:
            • Implement Stripe Elements for secure card input
            • Support Apple Pay and Google Pay
            • Handle 3D Secure authentication (SCA compliance)
            • Implement webhook handlers for payment events
            • Add payment retry logic for failed transactions
            • Create comprehensive error handling and user feedback

            ACCEPTANCE CRITERIA

            1. Users can successfully complete checkout using:
               ✓ Credit/debit cards (Visa, Mastercard, Amex)
               ✓ Apple Pay (on supported devices)
               ✓ Google Pay

            2. Payment flow handles:
               ✓ 3D Secure authentication when required
               ✓ Failed payment scenarios with clear error messages
               ✓ Network timeouts and retries

            3. Backend processes:
               ✓ Webhook events (payment.succeeded, payment.failed)
               ✓ Order status updates based on payment status
               ✓ Email confirmations sent on successful payment

            4. Testing:
               ✓ Unit tests for payment service (90%+ coverage)
               ✓ Integration tests with Stripe test mode
               ✓ E2E tests for complete checkout flow

            TECHNICAL NOTES

            API Documentation: stripe.com/docs/payments
            Test Cards: Use Stripe test card numbers
            Environment: Development Stripe keys in .env.development

            Dependencies:
            - PROJ-122: Checkout UI redesign (completed)
            - PROJ-124: Order management backend (in progress - won't block)

            RESOURCES

            • Stripe API docs: stripe.com/docs
            • Internal payment service docs: /docs/payments
            • Design mockups: figma.com/checkout-flow
            • Technical spec: confluence.com/payments-integration

            TEAM CONTACTS

            • Tech Lead: Mike Johnson (@mjohnson)
            • Product Manager: Lisa Chen (@lchen)
            • QA Engineer: Tom Wilson (@twilson)

            VIEW TASK IN JIRA: jira.com/task/PROJ-123

            Questions or need clarification? Comment on the ticket or reach out on Slack!

            Jira Notification System
            notifications@jira.com
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: View Task",
            intent: "project.task.assigned",
            intentConfidence: 0.98,
            suggestedActions: [
                EmailAction(actionId: "view_task", displayName: "View Task", actionType: .goTo, isPrimary: true, priority: 1, context: ["taskUrl": "https://jira.com/task/PROJ-123"]),
                EmailAction(actionId: "add_to_calendar", displayName: "Add Deadline", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Jira", initial: "J", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // view_incident
        cards.append(EmailCard(
            id: "proj3",
            type: .mail,
            state: .unseen,
            priority: .critical,
            hpa: "View Incident",
            timeAgo: "10m ago",
            title: "🚨 Production Incident - Database Slow",
            summary: "Critical incident #12345: Database performance degraded with 5-8 second page loads affecting 500-800 users. Query response time at 5,000ms - immediate response required.",

            aiGeneratedSummary: """
            **Actions:**
            • View and respond to critical incident **immediately**

            **Why:**
            High severity: Database queries timing out, users affected.

            **Context:**
            • Incident #12345
            • Multiple users impacted
            """,
            body: """
            🚨 CRITICAL INCIDENT: Database Performance Degradation

            INCIDENT ALERT

            Severity: HIGH
            Status: TRIGGERED
            Incident #: 12345
            Service: Production Database (db-prod-01)
            Time Detected: October 25, 2025 at 9:45 AM PST

            ISSUE SUMMARY

            Our monitoring systems have detected severe database performance degradation affecting production services. Multiple users are experiencing slow page loads and timeouts.

            IMPACT

            Affected Services:
            • User authentication (50% slower)
            • Product catalog (timing out)
            • Checkout flow (intermittent failures)
            • Admin dashboard (unresponsive)

            User Impact:
            • Approximately 500-800 active users affected
            • Page load times increased from 200ms to 5-8 seconds
            • Transaction failures: ~25% of checkout attempts
            • Geographic impact: All regions

            TECHNICAL DETAILS

            Symptoms:
            • Database query response time: 5,000ms average (normal: 50ms)
            • Connection pool saturation: 95/100 connections active
            • Slow query log showing multiple long-running queries
            • CPU utilization: 85% (normal: 20-30%)
            • Disk I/O: High read latency

            Potential Causes:
            1. Unoptimized query introduced in recent deployment
            2. Missing database index on high-traffic table
            3. Deadlock or blocking queries
            4. Database backup process still running

            IMMEDIATE ACTIONS NEEDED

            1. Acknowledge this incident in PagerDuty
            2. Join incident response channel: #incident-12345
            3. Review slow query log for problematic queries
            4. Check for recent deployments (last 2 hours)
            5. Consider rolling back recent changes if found

            RESPONSE TEAM

            Incident Commander: On-call Engineer (you)
            Database Administrator: Paged (awaiting response)
            Engineering Manager: Notified
            Product Manager: Notified

            LINKS & RESOURCES

            • View Incident: pagerduty.com/incident/12345
            • Grafana Dashboard: grafana.com/db-performance
            • Slow Query Log: logs.com/slow-queries
            • Runbook: wiki.com/db-incident-response
            • Incident Channel: slack.com/channels/incident-12345

            NEXT STEPS

            1. Acknowledge incident (click link below)
            2. Join incident response call if not auto-joined
            3. Begin investigation using runbook
            4. Post updates every 15 minutes to status page
            5. Page additional support if needed

            ACKNOWLEDGE INCIDENT: pagerduty.com/incident/12345/acknowledge

            Time is critical. Please respond immediately.

            PagerDuty Incident Management
            incidents@pagerduty.com
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: View Incident",
            intent: "project.incident.alert",
            intentConfidence: 1.0,
            suggestedActions: [
                EmailAction(actionId: "view_incident", displayName: "View Incident", actionType: .goTo, isPrimary: true, priority: 1, context: ["incidentUrl": "https://pagerduty.com/incident/12345"]),
                EmailAction(actionId: "acknowledge", displayName: "Acknowledge", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "PagerDuty", initial: "P", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // add_to_calendar
        cards.append(EmailCard(
            id: "proj4",
            type: .mail,
            state: .unseen,
            priority: .medium,
            hpa: "Add to Calendar",
            timeAgo: "1d ago",
            title: "Team All-Hands - Friday 2 PM",
            summary: "Q4 All-Hands meeting this Friday at 2 PM PST. CEO sharing Q3 results, Q4 roadmap, and department updates with live Q&A session.",

            aiGeneratedSummary: """
            **Actions:**
            • Add team all-hands to calendar for **Friday 2 PM**

            **Why:**
            Quarterly results and roadmap discussion.

            **Context:**
            • Attendance requested
            • CEO hosting
            """,
            body: """
            Invitation: Q4 All-Hands Meeting - This Friday

            Team,

            You're invited to our quarterly All-Hands meeting this Friday! The executive team has exciting updates to share about our Q3 results and Q4 roadmap.

            MEETING DETAILS

            What: Q4 All-Hands Meeting
            When: Friday, October 27, 2025 at 2:00 PM PST
            Duration: 90 minutes
            Where: Virtual (Zoom link below)
            Format: Presentation + Live Q&A

            Join: zoom.us/j/987654321
            Meeting ID: 987 654 321

            AGENDA

            Welcome & Opening Remarks (5 min)
            CEO, Jennifer Martinez

            Q3 Results & Company Update (25 min)
            - Revenue and growth metrics
            - Key wins and customer highlights
            - Team growth and new hires
            - Market position and competition

            Q4 Priorities & Roadmap (25 min)
            - Strategic initiatives for Q4
            - Product roadmap updates
            - Go-to-market strategy
            - Key performance targets

            Department Updates (20 min)
            - Engineering: Platform improvements
            - Product: New feature launches
            - Sales: Pipeline and deals
            - Marketing: Campaign results

            Recognition & Celebrations (10 min)
            - Top performers and team achievements
            - Work anniversaries
            - New team member introductions

            Open Q&A (15 min)
            Ask anything! Submit questions via Slido.

            WHY ATTEND

            This is your opportunity to:
            ✓ Hear directly from leadership about company direction
            ✓ Understand how your work contributes to company goals
            ✓ Learn about exciting projects coming up
            ✓ Ask questions and share feedback
            ✓ Connect with the entire team

            PARTICIPATION

            • Attendance is highly encouraged for all team members
            • Meeting will be recorded for those who can't attend live
            • Submit questions in advance: slido.com/q4-allhands
            • Feel free to turn on your camera and engage!

            CAN'T ATTEND?

            If you have a conflict, no problem! The recording and slide deck will be shared via email afterward. However, we'd love to see you there live if possible.

            ADD TO CALENDAR

            Download ICS file: calendar.com/add/q4-allhands
            Or manually add:
            • Title: Q4 All-Hands Meeting
            • Date: Friday, Oct 27, 2025
            • Time: 2:00 PM - 3:30 PM PST
            • Location: zoom.us/j/987654321

            Looking forward to seeing everyone on Friday!

            Best regards,

            Jennifer Martinez
            CEO
            jennifer@company.com
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Add to Calendar",
            intent: "project.meeting.invitation",
            intentConfidence: 0.95,
            suggestedActions: [
                EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: true, priority: 1, context: ["eventDate": "Friday 2 PM", "eventTitle": "Team All-Hands"]),
                EmailAction(actionId: "view_details", displayName: "View Details", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "CEO", initial: "C", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // MARK: - LEARNING (2 actions)

        // register_event
        cards.append(EmailCard(
            id: "learn1",
            type: .mail,
            state: .unseen,
            priority: .medium,
            hpa: "Register",
            timeAgo: "4h ago",
            title: "Free Webinar: AI for Developers",
            summary: "Free AI webinar Thursday Oct 26 at 11 AM PST covering LLMs, prompt engineering, and integration patterns. Includes live coding demo and Q&A with OpenAI and Anthropic experts.",

            aiGeneratedSummary: """
            **Actions:**
            • Register for AI webinar on **Thursday**

            **Why:**
            Deep dive into LLMs and prompt engineering.

            **Context:**
            • Free event
            • Tech Conference hosted
            """,
            body: """
            Free Webinar: AI for Developers - Thursday Oct 26

            You're Invited to an Exclusive Learning Event

            Hi Sarah,

            We're excited to invite you to our upcoming webinar on AI and Large Language Models for developers. This free, interactive session will give you practical insights into integrating AI into your applications.

            WEBINAR DETAILS

            Topic: AI for Developers: LLMs & Prompt Engineering
            Date: Thursday, October 26, 2025
            Time: 11:00 AM - 12:30 PM PST
            Duration: 90 minutes (60 min presentation + 30 min Q&A)
            Cost: FREE
            Format: Live virtual event with recording available

            WHAT YOU'LL LEARN

            Introduction to Large Language Models (20 min)
            • How LLMs work under the hood
            • Popular models: GPT-4, Claude, PaLM
            • Use cases and applications
            • Cost considerations and model selection

            Prompt Engineering Best Practices (25 min)
            • Writing effective prompts
            • Few-shot vs zero-shot learning
            • Chain-of-thought prompting
            • Common pitfalls and how to avoid them

            Integration Patterns & Architecture (15 min)
            • API integration strategies
            • Handling rate limits and retries
            • Caching and cost optimization
            • Security and privacy considerations

            Live Coding Demo (15 min)
            • Building a simple AI-powered feature
            • Real-time prompt iteration
            • Testing and evaluation

            Q&A Session (30 min)
            • Ask our expert panel anything about AI

            WHO SHOULD ATTEND

            This webinar is perfect for:
            ✓ Backend and full-stack developers
            ✓ Technical leads and architects
            ✓ Product managers working on AI features
            ✓ Anyone curious about integrating AI into applications

            Prerequisites: Basic programming knowledge helpful but not required

            YOUR SPEAKERS

            Dr. Emily Chen
            AI Research Lead at OpenAI
            10+ years in machine learning and NLP

            Marcus Rodriguez
            Senior Staff Engineer at Anthropic
            Built production AI systems at scale

            Sarah Williams
            Developer Relations, Google AI
            Specializes in making AI accessible to developers

            BONUS MATERIALS

            All registered attendees receive:
            ✓ Slide deck and code samples
            ✓ Prompt engineering cheat sheet
            ✓ Curated list of AI developer resources
            ✓ Recording of the webinar (available for 30 days)
            ✓ Certificate of attendance

            REGISTER NOW (FREE)

            Spaces are limited! Secure your spot today.

            REGISTER: webinar.com/register/ai-dev

            After registering, you'll receive:
            • Calendar invite with Zoom link
            • Pre-webinar preparation materials
            • Reminder emails before the event

            Can't attend live? Register anyway to receive the recording!

            Questions? Reply to this email or visit our FAQ: techconference.com/webinar-faq

            We look forward to seeing you Thursday!

            Best regards,

            The Tech Conference Team
            events@techconference.com
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Register",
            intent: "event.webinar.invitation",
            intentConfidence: 0.94,
            suggestedActions: [
                EmailAction(actionId: "register_event", displayName: "Register", actionType: .goTo, isPrimary: true, priority: 1, context: ["registrationUrl": "https://webinar.com/register/ai-dev"]),
                EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Tech Conference", initial: "T", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // take_survey
        cards.append(EmailCard(
            id: "learn2",
            type: .mail,
            state: .unseen,
            priority: .low,
            hpa: "Take Survey",
            timeAgo: "2d ago",
            title: "We'd Love Your Feedback",
            summary: "Quick 2-minute product feedback survey to help shape future features. Enter to win one of five $100 Amazon gift cards - closes November 10.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            Feedback survey with chance to win $100 gift card.

            **Context:**
            • Takes 2 minutes
            • Optional participation
            """,
            body: """
            We'd Love Your Feedback!

            Hi Sarah,

            We hope you've been enjoying our product! We're always looking to improve, and your feedback is invaluable to help us build better features and experiences.

            QUICK SURVEY - 2 MINUTES

            We've created a short survey to understand how we're doing and what we can improve. It'll take just 2 minutes of your time, and your input will directly influence our product roadmap.

            TAKE SURVEY: survey.com/feedback

            WHAT WE'LL ASK

            The survey covers:
            • Overall satisfaction with our product
            • Which features you use most
            • Any pain points or challenges
            • Features you'd like to see added
            • How likely you are to recommend us

            YOUR FEEDBACK MATTERS

            Here's how we use your responses:
            ✓ Prioritize feature development based on user needs
            ✓ Identify and fix pain points quickly
            ✓ Improve onboarding and user experience
            ✓ Make data-driven product decisions

            Recent improvements made from customer feedback:
            • Faster search functionality (requested by 45% of users)
            • Dark mode option (top requested feature)
            • Bulk export feature (saves time for power users)

            THANK YOU INCENTIVE

            As a token of our appreciation, all survey participants will be entered to win one of five $100 Amazon gift cards!

            Winners will be randomly selected and notified via email by November 15th. No purchase necessary, void where prohibited.

            PRIVACY & ANONYMITY

            Your responses are confidential and will be aggregated with other feedback. We won't share your individual responses outside our product team, and you can choose to remain anonymous.

            Questions are optional - feel free to skip any you prefer not to answer!

            TAKE THE SURVEY

            Ready to share your thoughts?

            START SURVEY: survey.com/feedback

            Survey closes: November 10, 2025

            HAVE MORE TO SAY?

            The survey is brief, but if you have additional feedback or ideas, we'd love to hear them! Feel free to:
            • Email us: feedback@company.com
            • Schedule a 1-on-1 call: calendly.com/product-team
            • Join our user community: community.company.com

            Thank you for being a valued customer. Your voice helps shape the future of our product!

            Best regards,

            Customer Success Team
            feedback@company.com

            P.S. This survey is completely optional, but we genuinely appreciate your time and input!
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Take Survey",
            intent: "feedback.survey.request",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "take_survey", displayName: "Take Survey", actionType: .goTo, isPrimary: true, priority: 1, context: ["surveyUrl": "https://survey.com/feedback"]),
                EmailAction(actionId: "view_details", displayName: "View Details", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Customer Success", initial: "C", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // MARK: - TRAVEL (3 actions)

        // check_in_flight
        cards.append(EmailCard(
            id: "travel1",
            type: .ads,
            state: .unseen,
            priority: .critical,
            hpa: "Check In",
            timeAgo: "1h ago",
            title: "Check In Now - Flight UA 123",
            summary: "United Airlines flight UA 123 to San Francisco departs tomorrow at 9:00 AM from LAX. Check in now to select your seat and get mobile boarding pass.",

            aiGeneratedSummary: """
            **Actions:**
            • Check in for flight **tomorrow 9:00 AM** to SFO

            **Why:**
            Check-in now available for United flight.

            **Context:**
            • Flight: UA 123
            • Destination: SFO
            """,
            body: """
            It's Time to Check In - Flight UA 123 to San Francisco

            Hi Sarah,

            Your flight to San Francisco is tomorrow! Check in now to secure your seat and get your boarding pass.

            FLIGHT INFORMATION

            Flight: UA 123
            Date: Tomorrow, October 26, 2025
            Departure: 9:00 AM PST from LAX (Terminal 7)
            Arrival: 10:45 AM PST at SFO (Terminal 3)
            Confirmation: ABC123

            Passenger: Sarah Chen
            Seat: Not yet assigned (select during check-in)

            CHECK IN NOW

            Online check-in is available! Get your mobile boarding pass and choose your preferred seat.

            CHECK IN: united.com/checkin/ABC123

            AVAILABLE SERVICES

            During check-in, you can:
            ✓ Choose or change your seat (free selection available)
            ✓ Add checked bags ($35 first bag, $45 second bag)
            ✓ Upgrade to Economy Plus ($59) or First Class ($189)
            ✓ Add Wi-Fi pass ($8 for full flight)
            ✓ Pre-order meals and snacks
            ✓ Add TSA PreCheck® to your boarding pass

            FLIGHT DETAILS

            Aircraft: Boeing 737-800
            Flight Duration: 1 hour 45 minutes
            Amenities: In-flight Wi-Fi, Streaming entertainment, Power outlets

            Baggage Allowance:
            • Carry-on: 1 bag + 1 personal item (free)
            • Checked: Pay per bag at check-in or airport

            WHAT TO EXPECT TOMORROW

            Recommended Timeline:
            • Arrive at LAX by 7:30 AM (1.5 hours before departure)
            • TSA security: Terminal 7, estimated wait 15-25 min
            • Boarding begins: 8:30 AM (30 minutes before departure)
            • Gate: Will be assigned 2-3 hours before departure (check app)

            Don't forget to:
            ✓ Bring government-issued photo ID
            ✓ Download United app for real-time updates
            ✓ Check TSA guidelines for carry-on items
            ✓ Arrive early to account for traffic and security

            MOBILE BOARDING PASS

            After checking in, you can:
            • Download boarding pass to United app
            • Add boarding pass to Apple Wallet or Google Pay
            • Print at home or at airport kiosk
            • Receive boarding pass via email

            REAL-TIME UPDATES

            We'll keep you informed about:
            • Gate assignments and changes
            • Boarding time and delays
            • Baggage claim information
            • Connection details

            NEED TO MAKE CHANGES?

            • Change flight: united.com/manage-booking
            • Cancel trip: Full refund if canceled within 24 hours of booking
            • Contact us: 1-800-864-8331 (24/7 support)

            Have a great flight tomorrow!

            United Airlines
            Customer Service
            reservations@united.com

            Confirmation Code: ABC123
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Check In",
            intent: "travel.flight.check-in",
            intentConfidence: 1.0,
            suggestedActions: [
                EmailAction(actionId: "check_in_flight", displayName: "Check In", actionType: .inApp, isPrimary: true, priority: 1, context: ["flightNumber": "UA 123", "airline": "United Airlines", "url": "https://united.com/checkin/ABC123", "departureTime": "Tomorrow 9:00 AM", "destination": "SFO"]),
                EmailAction(actionId: "view_itinerary", displayName: "View Itinerary", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "add_to_wallet", displayName: "Add to Wallet", actionType: .inApp, isPrimary: false, priority: 3)
            ],
            sender: SenderInfo(name: "United Airlines", initial: "U", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: "United Airlines",
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // view_itinerary
        cards.append(EmailCard(
            id: "travel2",
            type: .ads,
            state: .unseen,
            priority: .high,
            hpa: "View Itinerary",
            timeAgo: "3h ago",
            title: "Trip Confirmation - San Francisco",
            summary: "San Francisco trip confirmed October 25-28 with United Airlines flights and Hyatt Regency hotel. Total cost $1,247.89 - check in Friday at 3 PM.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            San Francisco trip confirmed with hotel and flight.

            **Context:**
            • Dates: October 25-28
            • Hotel: Hyatt Regency
            """,
            body: """
            Your San Francisco Trip is Confirmed!

            Hi Sarah,

            Great news! Your San Francisco getaway is all set. We've put together everything you need for a smooth trip.

            TRIP SUMMARY

            Destination: San Francisco, California
            Dates: October 25-28, 2025 (3 nights)
            Booking Reference: EXP-SF-8472
            Total Trip Cost: $1,247.89

            YOUR ITINERARY

            FLIGHT OUT - Friday, October 25
            United Airlines UA 123
            Depart: Los Angeles (LAX) 9:00 AM
            Arrive: San Francisco (SFO) 10:45 AM
            Flight time: 1h 45m | Economy Class
            Confirmation: ABC123

            HOTEL - 3 Nights
            Hyatt Regency San Francisco
            5 Embarcadero Center, San Francisco, CA 94111

            Check-in: Friday, October 25, 2025 (3:00 PM)
            Check-out: Monday, October 28, 2025 (11:00 AM)
            Room Type: King Bed Room with City View
            Confirmation: HYT-9284756

            Room Amenities:
            ✓ Free Wi-Fi
            ✓ Fitness center access
            ✓ Business center
            ✓ In-room coffee maker
            ✓ City views from the 18th floor

            Hotel Contact: (415) 788-1234

            FLIGHT RETURN - Monday, October 28
            United Airlines UA 456
            Depart: San Francisco (SFO) 2:00 PM
            Arrive: Los Angeles (LAX) 3:45 PM
            Flight time: 1h 45m | Economy Class
            Confirmation: DEF456

            PRICING BREAKDOWN

            Flights (roundtrip):           $398.00
            Hotel (3 nights @ $249/night): $747.00
            Taxes & Fees:                  $102.89
            ─────────────────────────────────────
            Total Paid:                   $1,247.89

            Payment Method: Visa ending in 4242
            Booking Date: October 20, 2025

            BEFORE YOU GO

            Checklist:
            ☐ Check in for your flight 24 hours before departure
            ☐ Download mobile boarding pass
            ☐ Review hotel amenities and policies
            ☐ Check weather forecast (current: 65°F, partly cloudy)
            ☐ Arrange airport transportation

            What to Pack:
            • Light jacket (SF can be cool, especially in the evening)
            • Comfortable walking shoes
            • Sunglasses and sunscreen
            • Camera for those iconic views!

            THINGS TO DO IN SAN FRANCISCO

            Don't Miss:
            • Golden Gate Bridge
            • Fisherman's Wharf & Pier 39
            • Alcatraz Island (book tickets ahead!)
            • Cable car rides
            • Chinatown
            • Ferry Building Marketplace

            Local Favorites:
            • Sourdough bread at Boudin Bakery
            • Clam chowder in a bread bowl
            • Ghirardelli chocolate
            • Coffee at Blue Bottle

            NEED HELP?

            Manage Your Trip:
            • View full itinerary: expedia.com/trip/abc123
            • Make changes: expedia.com/manage-booking
            • Add activities: expedia.com/things-to-do/san-francisco
            • Travel insurance: Available for $49.99

            Contact Us:
            • 24/7 Customer Support: 1-877-227-7481
            • Live Chat: expedia.com/help
            • Email: support@expedia.com

            Download the Expedia app for:
            ✓ Mobile itinerary access
            ✓ Real-time flight updates
            ✓ Hotel check-in
            ✓ Local recommendations

            Have an amazing trip to San Francisco!

            Safe travels,

            The Expedia Team
            travel@expedia.com

            Trip Reference: EXP-SF-8472
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: View Itinerary",
            intent: "travel.itinerary.confirmation",
            intentConfidence: 0.98,
            suggestedActions: [
                EmailAction(actionId: "view_itinerary", displayName: "View Itinerary", actionType: .goTo, isPrimary: true, priority: 1, context: ["itineraryUrl": "https://expedia.com/trip/abc123"]),
                EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Expedia", initial: "E", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // add_to_wallet
        cards.append(EmailCard(
            id: "travel3",
            type: .ads,
            state: .unseen,
            priority: .medium,
            hpa: "Add to Wallet",
            timeAgo: "1d ago",
            title: "Your Boarding Pass is Ready",
            summary: "Delta flight DL 567 boarding pass ready for Monday Oct 30 at 6:00 PM from Atlanta to LAX. Add to Apple Wallet for easy airport access and real-time updates.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            Boarding pass ready to add to Apple Wallet.

            **Context:**
            • Delta flight
            • Easy airport access
            """,
            body: """
            Your Boarding Pass is Ready!

            Hi Sarah,

            You're all set for your upcoming Delta flight! Your mobile boarding pass is ready to use.

            FLIGHT INFORMATION

            Flight: DL 567
            Date: Monday, October 30, 2025
            Departure: 6:00 PM EST from ATL (Terminal S, Gate A12)
            Arrival: 8:45 PM PST at LAX (Terminal 2)

            Passenger: Sarah Chen
            Confirmation: DL5X8P9
            Seat: 14A (Window)

            MOBILE BOARDING PASS

            For the fastest airport experience, add your boarding pass to your mobile wallet. You'll be able to:

            ✓ Go straight to security (no check-in needed)
            ✓ Access your pass even without internet
            ✓ Receive real-time gate and time updates
            ✓ Board directly by scanning your phone

            ADD TO WALLET

            iPhone: Add to Apple Wallet (one tap!)
            Android: Add to Google Pay

            Your boarding pass includes:
            • QR code for scanning at gates and security
            • TSA PreCheck® indicator (if enrolled)
            • Real-time flight status
            • Gate and boarding time updates

            AIRPORT INFORMATION

            Hartsfield-Jackson Atlanta International Airport
            Terminal S (South Terminal)
            Gate: A12 (subject to change - check app for updates)

            Recommended Arrival: 4:30 PM (1.5 hours before departure)
            TSA Security: Allow 20-30 minutes
            Boarding Time: 5:30 PM (30 minutes before departure)

            YOUR FLIGHT DETAILS

            Aircraft: Boeing 757-200
            Flight Duration: 4 hours 45 minutes
            Class: Main Cabin (Economy)
            Seat: 14A (Window seat with extra legroom)

            Included:
            ✓ Personal item (fits under seat)
            ✓ Carry-on bag (overhead bin)
            ✓ In-flight entertainment system
            ✓ Free snacks and non-alcoholic beverages
            ✓ Wi-Fi available for purchase ($8 full flight)

            PREPARE FOR YOUR TRIP

            Before You Leave:
            ☐ Check flight status for any changes
            ☐ Download Delta app for real-time updates
            ☐ Bring government-issued photo ID
            ☐ Review TSA carry-on guidelines
            ☐ Charge your devices

            At The Airport:
            ☐ Arrive 90 minutes before departure
            ☐ Have boarding pass and ID ready for TSA
            ☐ Monitor gate information (can change)
            ☐ Board during your zone (Zone 2)

            FLIGHT STATUS UPDATES

            We'll keep you informed about:
            • Gate assignments and changes
            • Boarding time
            • Delays or schedule changes
            • Baggage claim carousel

            Download the Fly Delta app for push notifications!

            NEED ASSISTANCE?

            Make Changes:
            • Change seat: delta.com/manage-booking
            • Upgrade cabin: Available at gate (subject to availability)
            • Add bags: $35 first checked bag

            Contact Us:
            • Delta App: Chat with virtual assistant
            • Phone: 1-800-221-1212 (24/7 support)
            • Airport: Visit Delta service desk

            SPECIAL SERVICES

            • Special assistance: Request at gate or call ahead
            • Wheelchair service: Available upon request
            • Dietary needs: Snacks and meals available for purchase

            Have a great flight!

            Delta Air Lines
            Customer Service
            reservations@delta.com

            Confirmation: DL5X8P9
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Add to Wallet",
            intent: "travel.boarding-pass.available",
            intentConfidence: 0.99,
            suggestedActions: [
                EmailAction(actionId: "add_to_wallet", displayName: "Add to Wallet", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "view_details", displayName: "View Pass", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Delta", initial: "D", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: "Delta",
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // MARK: - ACCOUNT (5 actions)

        // reset_password
        cards.append(EmailCard(
            id: "acct1",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "Reset Password",
            timeAgo: "30m ago",
            title: "Password Reset Request",
            summary: "Password reset link sent for sarah.chen@email.com. Complete reset within 1 hour before link expires - ignore if you didn't request this.",

            aiGeneratedSummary: """
            **Actions:**
            • Reset password within **1 hour** before link expires

            **Why:**
            Password reset requested for your account.

            **Context:**
            • Link expires soon
            • Report if you didn't request this
            """,
            body: """
            Password Reset Request

            Hi Sarah,

            We received a request to reset the password for your account (sarah.chen@email.com).

            RESET YOUR PASSWORD

            If you requested this password reset, click the button below to create a new password. This link will expire in 1 hour for security reasons.

            RESET PASSWORD: account.com/reset/token123

            The link expires at: October 25, 2025 at 10:45 AM PST

            DIDN'T REQUEST THIS?

            If you didn't request a password reset, please ignore this email. Your password will remain unchanged and your account is secure.

            However, if you're concerned about unauthorized access:
            1. Don't click the reset link above
            2. Review recent login activity in your account settings
            3. Contact our security team immediately
            4. Consider enabling two-factor authentication

            Report Suspicious Activity: security@company.com

            SECURITY TIPS

            Keep Your Account Safe:
            ✓ Use a strong, unique password (12+ characters)
            ✓ Enable two-factor authentication (2FA)
            ✓ Never share your password with anyone
            ✓ Use a password manager
            ✓ Update passwords regularly
            ✓ Be cautious of phishing emails

            Creating a Strong Password:
            • Mix uppercase and lowercase letters
            • Include numbers and special characters
            • Avoid common words or personal information
            • Don't reuse passwords across sites

            HOW THIS WORKS

            When you click the reset link:
            1. You'll be taken to a secure page
            2. Enter your new password twice to confirm
            3. Your password will be updated immediately
            4. You'll be logged out of all devices
            5. You can log back in with your new password

            ADDITIONAL INFORMATION

            Request Details:
            • Time: October 25, 2025 at 9:45 AM PST
            • IP Address: 192.168.1.100
            • Location: Los Angeles, CA
            • Device: Chrome on Mac OS

            If this information doesn't match your request, contact us immediately.

            NEED HELP?

            If you're having trouble resetting your password:
            • Check spam folder for this email
            • Make sure link hasn't expired
            • Try copying and pasting the full URL
            • Contact support for assistance

            Contact Support:
            • Email: support@company.com
            • Phone: 1-800-555-0199 (24/7)
            • Help Center: help.company.com

            Thank you for keeping your account secure!

            Account Security Team
            security@company.com

            ---
            This is an automated security email. Please do not reply directly to this message.
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Reset Password",
            intent: "account.password.reset",
            intentConfidence: 1.0,
            suggestedActions: [
                EmailAction(actionId: "reset_password", displayName: "Reset Password", actionType: .goTo, isPrimary: true, priority: 1, context: ["resetUrl": "https://account.com/reset/token123"]),
                EmailAction(actionId: "report_suspicious", displayName: "Didn't request this?", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Account Security", initial: "A", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // verify_account
        cards.append(EmailCard(
            id: "acct2",
            type: .mail,
            state: .unseen,
            priority: .critical,
            hpa: "Verify Account",
            timeAgo: "15m ago",
            title: "Verify Your Email Address",
            summary: "Complete Slack account setup by verifying sarah.chen@email.com. Click verification link within 24 hours to activate account and start collaborating with your team.",

            aiGeneratedSummary: """
            **Actions:**
            • Verify email address to complete Slack account setup

            **Why:**
            Account verification required to access Slack.

            **Context:**
            • Click verification link
            • Can resend if needed
            """,
            body: """
            Verify Your Email Address for Slack

            Welcome to Slack!

            Hi Sarah,

            Thanks for signing up! To complete your Slack account setup and start collaborating with your team, please verify your email address.

            VERIFY YOUR EMAIL

            Click the button below to confirm your email address (sarah.chen@email.com) and activate your account:

            VERIFY EMAIL: account.com/verify/token456

            This verification link is valid for 24 hours.

            WHY VERIFY?

            Email verification helps us:
            ✓ Confirm you're a real person
            ✓ Protect your account from unauthorized access
            ✓ Enable password recovery options
            ✓ Send you important account notifications
            ✓ Keep our community secure

            Once verified, you'll be able to:
            • Join your workspace
            • Start messaging your team
            • Access channels and direct messages
            • Customize your profile
            • Connect integrations and apps

            GETTING STARTED WITH SLACK

            After verification, here's what to do:

            1. Complete Your Profile
               • Add a photo
               • Write a short bio
               • Set your status
               • Add your role and department

            2. Join Channels
               • Browse available channels
               • Join relevant teams and projects
               • Create new channels if needed

            3. Set Up Notifications
               • Choose your notification preferences
               • Set do-not-disturb hours
               • Customize for mobile and desktop

            4. Connect Tools
               • Integrate with Google Drive, Zoom, etc.
               • Set up workflow automations
               • Add helpful Slack apps

            SLACK QUICK TIPS

            Keyboard Shortcuts:
            • Cmd/Ctrl + K: Quick switcher
            • Cmd/Ctrl + /: View all shortcuts
            • @mention: Notify specific people
            • /remind: Set reminders

            Features You'll Love:
            • Threads: Keep conversations organized
            • Reactions: Quick responses with emoji
            • Search: Find any message, file, or person
            • Huddles: Quick audio conversations
            • Clips: Record audio, video, or screen

            DIDN'T SIGN UP?

            If you didn't create this Slack account, please ignore this email. The account will not be activated without email verification.

            To report this, contact: abuse@slack.com

            LINK NOT WORKING?

            If the verification button doesn't work:
            1. Copy and paste this URL into your browser:
               account.com/verify/token456

            2. Make sure you're using the same browser where you signed up

            3. Check if the link has expired (24 hour limit)

            4. Request a new verification email

            NEED HELP?

            Having trouble verifying your email?

            • Resend verification email
            • Check your spam/junk folder
            • Add noreply@slack.com to contacts
            • Visit our help center

            Contact Support:
            • Help Center: slack.com/help
            • Email: support@slack.com
            • Twitter: @SlackHQ

            We're excited to have you on Slack! Once you verify your email, you'll be ready to communicate and collaborate with your team.

            Welcome aboard!

            The Slack Team
            noreply@slack.com

            ---
            This is an automated email. Please do not reply to this message.

            Slack Technologies, LLC
            500 Howard Street, San Francisco, CA 94105
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Verify Account",
            intent: "account.verification.required",
            intentConfidence: 1.0,
            suggestedActions: [
                EmailAction(actionId: "verify_account", displayName: "Verify Account", actionType: .goTo, isPrimary: true, priority: 1, context: ["verifyUrl": "https://account.com/verify/token456"]),
                EmailAction(actionId: "resend_email", displayName: "Resend Email", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Slack", initial: "S", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // verify_device
        cards.append(EmailCard(
            id: "acct3",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "Verify Device",
            timeAgo: "1h ago",
            title: "New Device Sign-In Detected",
            summary: "Security alert: New sign-in from iPhone 15 Pro in San Francisco detected at 9:00 AM. Verify if this was you or secure your account immediately.",

            aiGeneratedSummary: """
            **Actions:**
            • Verify device login or secure account

            **Why:**
            New login from iPhone in San Francisco detected.

            **Context:**
            • Confirm if this was you
            • Take action if suspicious
            """,
            body: """
            New Device Sign-In Detected

            Security Alert

            Hi Sarah,

            We detected a new sign-in to your Google Account (sarah.chen@email.com) from a device you haven't used before.

            SIGN-IN DETAILS

            Device: iPhone 15 Pro
            Location: San Francisco, California, USA
            Time: October 25, 2025 at 9:00 AM PST
            IP Address: 192.168.1.105
            Browser: Safari 17.0

            WAS THIS YOU?

            If you just signed in from a new device in San Francisco, you can ignore this message. Your account is secure.

            VERIFY THIS DEVICE: account.com/verify-device

            Click above to confirm this was you and trust this device for future sign-ins.

            THIS WASN'T YOU?

            If you don't recognize this activity, someone else might have access to your account. Take action immediately:

            1. Secure Your Account (URGENT)
               • Change your password right away
               • Enable 2-factor authentication (2FA)
               • Review recent activity

            2. Review Connected Devices
               • Check all devices with account access
               • Remove any you don't recognize
               • Sign out of all other sessions

            3. Check Recent Activity
               • Review recent emails sent
               • Check for unauthorized changes
               • Verify recovery email and phone

            SECURE ACCOUNT NOW: account.com/security-checkup

            WHY THIS MATTERS

            We monitor sign-ins from new devices to protect you from unauthorized access. This alert helps you:

            ✓ Detect suspicious activity early
            ✓ Prevent account compromise
            ✓ Protect your personal data
            ✓ Maintain control of your account

            PROTECT YOUR ACCOUNT

            Security Best Practices:
            • Use a strong, unique password
            • Enable 2-factor authentication (2FA)
            • Keep recovery info up to date
            • Review security settings regularly
            • Don't share your password
            • Be wary of phishing emails

            Enable 2FA Now:
            Add an extra layer of security by requiring a code from your phone when signing in. This prevents unauthorized access even if someone has your password.

            SETUP 2FA: account.com/2fa-setup

            YOUR ACCOUNT STATUS

            Current Security Level: Medium
            2-Factor Authentication: Not Enabled (Recommended)
            Recent Activity: No suspicious activity detected
            Recovery Email: On file
            Recovery Phone: On file

            WHAT HAPPENS NEXT

            If you verify this device:
            • We'll remember it for future sign-ins
            • You won't need to verify it again
            • You can manage it in your devices list

            If you don't verify within 48 hours:
            • We'll automatically sign out this device
            • You'll need to verify again next time
            • No further action is required from you

            NEED HELP?

            If you're having issues or need assistance:

            Contact Support:
            • Help Center: support.google.com
            • Security Help: google.com/security
            • Report suspicious activity: Report form

            Google Account Security Team
            noreply-security@google.com

            ---
            This is an automated security message. Google will never ask for your password via email.

            Google LLC, 1600 Amphitheatre Parkway, Mountain View, CA 94043
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Verify Device",
            intent: "account.device.verification",
            intentConfidence: 0.98,
            suggestedActions: [
                EmailAction(actionId: "verify_device", displayName: "Yes, it was me", actionType: .goTo, isPrimary: true, priority: 1, context: ["verifyUrl": "https://account.com/verify-device"]),
                EmailAction(actionId: "review_security", displayName: "No, secure account", actionType: .goTo, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Google", initial: "G", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // review_security
        cards.append(EmailCard(
            id: "acct4",
            type: .mail,
            state: .unseen,
            priority: .critical,
            hpa: "Review Security",
            timeAgo: "10m ago",
            title: "🔐 Security Alert: Unusual Activity",
            summary: "Critical: 5 failed login attempts to your Apple ID from Moscow, Russia. Account temporarily locked for protection - review security and change password immediately.",

            aiGeneratedSummary: """
            **Actions:**
            • Review security alert **immediately**

            **Why:**
            Unusual activity detected on your Apple account.

            **Context:**
            • Critical security issue
            • Change password recommended
            """,
            body: """
            🔐 Security Alert: Unusual Activity Detected

            CRITICAL: Action Required

            Dear Sarah Chen,

            We've detected unusual activity on your Apple ID (sarah.chen@email.com) that requires your immediate attention.

            SUSPICIOUS ACTIVITY DETECTED

            Activity Type: Multiple failed login attempts
            Location: Moscow, Russia
            Time: October 25, 2025 at 9:50 AM PST
            Attempts: 5 failed login attempts in 10 minutes
            Status: Account temporarily locked for protection

            YOUR ACCOUNT IS CURRENTLY SECURE

            We blocked these login attempts and temporarily locked your account to protect you. No one has accessed your account or data.

            IMMEDIATE ACTIONS REQUIRED

            1. Review This Activity
               REVIEW SECURITY: account.com/security

            2. Change Your Password
               If you think your password may have been compromised, change it immediately.
               CHANGE PASSWORD: appleid.apple.com/change-password

            3. Enable Two-Factor Authentication
               Add an extra layer of security to prevent unauthorized access.
               ENABLE 2FA: appleid.apple.com/2fa

            WHAT THIS MEANS

            Someone tried to access your Apple ID multiple times from:
            • IP Address: 85.143.218.XXX
            • Location: Moscow, Russia
            • Device: Unknown Windows PC
            • Browser: Firefox

            This activity is highly unusual for your account, which typically signs in from:
            • Los Angeles, California
            • iPhone and MacBook
            • Safari browser

            HOW WE PROTECTED YOU

            ✓ Blocked all suspicious login attempts
            ✓ Temporarily locked your account
            ✓ Sent you this immediate notification
            ✓ Prevented any data access
            ✓ Alerted our security team

            UNLOCK YOUR ACCOUNT

            To regain access to your Apple ID:

            1. Click the link below to verify your identity
            2. Answer your security questions
            3. Change your password
            4. Set up two-factor authentication

            UNLOCK ACCOUNT: appleid.apple.com/unlock

            HOW THIS MAY HAVE HAPPENED

            Common ways accounts are compromised:
            • Password reused from another breached service
            • Phishing email that looked like Apple
            • Malware on a device you used
            • Public Wi-Fi without VPN
            • Weak or easily guessed password

            PROTECT YOUR ACCOUNT

            Take these steps to stay secure:

            1. Use a Strong, Unique Password
               • 12+ characters
               • Mix of letters, numbers, symbols
               • Never reused from other sites
               • Consider using a password manager

            2. Enable Two-Factor Authentication (CRITICAL)
               • Requires your device + password to sign in
               • Blocks access even if password is stolen
               • Receive alerts for any login attempts

            3. Review Security Settings
               • Check trusted devices
               • Update recovery email/phone
               • Review recent activity
               • Remove old devices

            4. Watch for Phishing
               • Apple never asks for passwords via email
               • Check sender email addresses carefully
               • Don't click suspicious links
               • Report phishing: reportphishing@apple.com

            WHAT'S AT RISK

            Your Apple ID protects:
            • iCloud data (photos, documents, backups)
            • Payment methods and purchases
            • iMessage and FaceTime
            • Find My iPhone
            • App Store and subscriptions
            • Personal information

            ACCOUNT STATUS

            Current Status: Temporarily Locked (for your protection)
            Security Level: At Risk
            2FA Status: Not Enabled (URGENT: Enable now)
            Last Successful Login: Oct 24, 2025 from Los Angeles
            Failed Login Attempts: 5 (from Moscow)

            NEED HELP?

            Our security team is here to assist 24/7:

            • Apple Support: 1-800-MY-APPLE (1-800-692-7753)
            • Support App: Get help in the Apple Support app
            • Online Chat: support.apple.com/chat
            • Visit Apple Store: Schedule Genius Bar appointment

            IMPORTANT REMINDER

            Apple will NEVER:
            • Ask for your password via email
            • Request payment to unlock your account
            • Call you unsolicited about security issues
            • Ask you to disable security features

            If someone claims to be from Apple and asks for these things, it's a scam. Hang up and contact Apple directly.

            Take action now to protect your account and data.

            Apple Security Team
            noreply@apple.com

            ---
            This is an automated security alert. Do not reply to this email.

            Apple Inc. | One Apple Park Way, Cupertino, CA 95014
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Review Security",
            intent: "account.security.alert",
            intentConfidence: 1.0,
            suggestedActions: [
                EmailAction(actionId: "review_security", displayName: "Review Security", actionType: .goTo, isPrimary: true, priority: 1, context: ["securityUrl": "https://account.com/security"]),
                EmailAction(actionId: "reset_password", displayName: "Change Password", actionType: .goTo, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Apple", initial: "A", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // revoke_secret
        cards.append(EmailCard(
            id: "acct5",
            type: .mail,
            state: .unseen,
            priority: .critical,
            hpa: "Revoke Access",
            timeAgo: "5m ago",
            title: "⚠️ API Key Exposed in Public Repo",
            summary: "Critical: AWS access key exposed in public GitHub repo sarah-chen/my-project. Revoke key immediately to prevent unauthorized access to your AWS resources.",

            aiGeneratedSummary: """
            **Actions:**
            • Revoke exposed API key **immediately**

            **Why:**
            API key found in public GitHub repository.

            **Context:**
            • Critical security breach
            • Generate new key after revoking
            """,

            body: """
            ⚠️ CRITICAL: API Key Exposed in Public Repository

            SECURITY ALERT - Immediate Action Required

            Hi Sarah,

            GitHub Secret Scanning has detected that your API key was accidentally committed to a public repository. This is a critical security issue that requires immediate attention.

            EXPOSED SECRET DETAILS

            Secret Type: AWS Access Key
            Repository: sarah-chen/my-project
            File: config/settings.py
            Commit: a3f5c8d - "Update configuration"
            Exposed: October 25, 2025 at 9:55 AM PST
            Public Exposure: 5 minutes (detected automatically)

            Exposed Key: AKIA...Q7X2 (partially redacted)

            IMMEDIATE RISK

            Your AWS credentials are now publicly visible and could be used by anyone to:
            • Access your AWS resources
            • Incur unexpected charges
            • Modify or delete data
            • Launch unauthorized services
            • Access sensitive information

            WHAT YOU MUST DO NOW

            1. Revoke the Exposed Key (CRITICAL - Do this first!)
               REVOKE ACCESS: aws.amazon.com/iam/revoke-key

            2. Generate a New Key
               After revoking, create a new AWS access key:
               CREATE KEY: aws.amazon.com/iam/create-key

            3. Update Your Applications
               • Replace the old key in all applications
               • Use environment variables instead of hardcoding
               • Never commit secrets to git

            4. Check for Unauthorized Usage
               • Review AWS CloudTrail logs
               • Check for unexpected resources
               • Monitor billing for unusual activity
               REVIEW ACTIVITY: aws.amazon.com/cloudtrail

            5. Clean Up Git History
               The key is still in your repository history!
               • Use BFG Repo-Cleaner or git filter-branch
               • Remove the secret from all commits
               • Force push to rewrite history
               LEARN HOW: docs.github.com/remove-secrets

            REPOSITORY DETAILS

            Repository: github.com/sarah-chen/my-project
            Branch: main
            Commit: a3f5c8d2e1b9f8c7a6d5e4f3b2a1c0d9e8f7a6b5
            File Path: config/settings.py
            Line: 47

            Exposed Code:
            ```
            AWS_ACCESS_KEY_ID = 'AKIAIOSFODNN7EXAMPLE'
            AWS_SECRET_ACCESS_KEY = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
            ```

            HOW WE DETECTED THIS

            GitHub Secret Scanning automatically monitors all public repositories for exposed credentials. We detected your AWS access key within minutes of it being committed and immediately:

            ✓ Sent you this alert
            ✓ Notified GitHub security team
            ✓ Notified AWS (if Secret Scanning partner)
            ✓ Recommended immediate revocation

            PREVENT THIS IN THE FUTURE

            Best Practices for Managing Secrets:

            1. Use Environment Variables
               Never hardcode secrets in source code. Use .env files and keep them out of git.

            2. Use .gitignore
               Add sensitive files to .gitignore:
               ```
               .env
               .env.local
               secrets.json
               config/credentials.*
               ```

            3. Use Secret Management Tools
               • AWS Secrets Manager
               • HashiCorp Vault
               • GitHub Secrets (for Actions)
               • Azure Key Vault
               • Google Secret Manager

            4. Enable Pre-Commit Hooks
               Use tools like:
               • git-secrets
               • detect-secrets
               • gitleaks
               • truffleHog

            5. Rotate Keys Regularly
               Even if not compromised, rotate credentials every 90 days.

            CHECKING FOR DAMAGE

            Review these areas for unauthorized activity:

            AWS Console Checks:
            □ EC2 instances (look for unknown instances)
            □ S3 buckets (check for data exfiltration)
            □ IAM users and roles (verify no new users)
            □ CloudTrail logs (review all API calls)
            □ Billing dashboard (check for unexpected charges)
            □ Security Hub alerts

            SECURITY RECOMMENDATIONS

            Current Status: HIGH RISK
            Recommended Actions: 6 critical actions required

            Priority 1 - Do Now:
            ✗ Revoke exposed AWS key
            ✗ Generate new credentials
            ✗ Remove secret from git history

            Priority 2 - Do Today:
            ✗ Review AWS CloudTrail for unauthorized activity
            ✗ Check AWS billing for unexpected charges
            ✗ Enable AWS GuardDuty for threat detection

            Priority 3 - Do This Week:
            ✗ Implement secrets management solution
            ✗ Set up pre-commit hooks
            ✗ Train team on secure credential handling

            ADDITIONAL RESOURCES

            • Removing secrets from git: docs.github.com/remove-secrets
            • AWS credential security: aws.amazon.com/security
            • GitHub secret scanning: docs.github.com/secret-scanning
            • Incident response guide: github.com/security/incident-response

            NEED HELP?

            GitHub Security Team:
            • Email: security@github.support
            • Docs: docs.github.com/security
            • Report: github.com/security/report

            AWS Support:
            • Console: aws.amazon.com/support
            • Phone: 1-866-947-4911
            • Docs: aws.amazon.com/security

            Time is critical. Please take action immediately to secure your account and resources.

            GitHub Secret Scanning
            Advanced Security Team
            security@github.com

            ---
            This alert was generated automatically by GitHub Advanced Security
            Do not reply to this email - use the links above for support

            GitHub, Inc. | 88 Colin P Kelly Jr St, San Francisco, CA 94107
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Revoke Access",
            intent: "account.secret.exposed",
            intentConfidence: 1.0,
            suggestedActions: [
                EmailAction(actionId: "revoke_secret", displayName: "Revoke Access", actionType: .goTo, isPrimary: true, priority: 1, context: ["revokeUrl": "https://account.com/api-keys"]),
                EmailAction(actionId: "view_details", displayName: "View Details", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "GitHub Security", initial: "G", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: nil,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // MARK: - ADDITIONAL FEATURE COVERAGE (7 cards)

        // Restaurant reservation - view_reservation
        cards.append(EmailCard(
            id: "rest1",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "View Reservation",
            timeAgo: "2h ago",
            title: "Reservation Confirmed - The French Laundry",
            summary: "Dinner reservation confirmed at The French Laundry for Friday, November 1st at 7:30 PM. Party of 2 with window seat - arrive 10 minutes early, business casual.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            Dinner reservation confirmed at The French Laundry.

            **Context:**
            • Date: Friday, November 1st at 7:30 PM
            • Party size: 2 guests, window seat
            """,

            body: "Congratulations! Your reservation at The French Laundry has been confirmed.\n\nReservation Details:\nDate: Friday, November 1, 2024\nTime: 7:30 PM\nParty Size: 2 guests\nTable: Window seat (as requested)\nConfirmation: #FL-2024-8392\n\nImportant Notes:\n- Please arrive 10 minutes early\n- Business casual dress code\n- Cancellation policy: 48 hours notice required\n- Special dietary requirements noted: Vegetarian option for one guest\n\nNeed to modify? Visit your reservation page or call us at (707) 944-2380.\n\nWe look forward to serving you!\n\nThe French Laundry\nYountville, California",
            htmlBody: nil,
            metaCTA: "Swipe Right: View Reservation",
            intent: "dining.reservation.confirmation",
            intentConfidence: 0.99,
            suggestedActions: [
                EmailAction(actionId: "view_reservation", displayName: "View Reservation", actionType: .goTo, isPrimary: true, priority: 1, context: ["reservationUrl": "https://opentable.com/reservation/FL-2024-8392", "confirmationCode": "FL-2024-8392"]),
                EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 2, context: ["eventDate": "Friday 7:30 PM", "eventTitle": "Dinner at The French Laundry"]),
                EmailAction(actionId: "modify_reservation", displayName: "Modify", actionType: .goTo, isPrimary: false, priority: 3, context: ["reservationUrl": "https://opentable.com/modify/FL-2024-8392", "confirmationCode": "FL-2024-8392"])
            ],
            sender: SenderInfo(name: "OpenTable", initial: "O", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // Food delivery - track_delivery
        cards.append(EmailCard(
            id: "food1",
            type: .ads,
            state: .unseen,
            priority: .critical,
            hpa: "Track Delivery",
            timeAgo: "5m ago",
            title: "Your DoorDash Order is On the Way!",
            summary: "Your Chipotle order is arriving in 15 minutes. Marcus is delivering your chicken burrito bowl and chips - track in real-time.",

            aiGeneratedSummary: """
            **Actions:**
            • Track delivery arriving in **15 minutes**

            **Why:**
            Marcus is delivering your Chipotle order.

            **Context:**
            • Order #DD-2938475
            • Total: $26.96
            """,

            body: "Your Order is Out for Delivery!\n\nOrder #DD-2938475\nRestaurant: Chipotle Mexican Grill\nDelivery Address: 123 Market St, San Francisco\n\nItems:\n- Chicken Burrito Bowl (x1)\n- Chips & Guacamole (x1)\n- Mexican Coca-Cola (x1)\n\nEstimated Arrival: 6:45 PM (15 minutes)\n\nYour Dasher:\nMarcus J. - ⭐ 4.9 rating\nVehicle: Black Honda Civic\n\nTrack your order in real-time to see exactly where Marcus is!\n\nOrder Total: $18.47\nDelivery Fee: $2.99\nService Fee: $1.50\nTip: $4.00\nTotal: $26.96\n\nHave a great meal!\nDoorDash",
            htmlBody: nil,
            metaCTA: "Swipe Right: Track Delivery",
            intent: "food-delivery.tracking.active",
            intentConfidence: 1.0,
            suggestedActions: [
                EmailAction(actionId: "track_delivery", displayName: "Track Delivery", actionType: .goTo, isPrimary: true, priority: 1, context: ["trackingUrl": "https://doordash.com/track/DD-2938475", "driverName": "Marcus J.", "eta": "15 minutes"]),
                EmailAction(actionId: "contact_driver", displayName: "Contact Driver", actionType: .goTo, isPrimary: false, priority: 2, context: ["contactUrl": "https://doordash.com/contact-dasher/DD-2938475"]),
                EmailAction(actionId: "view_order", displayName: "View Order", actionType: .inApp, isPrimary: false, priority: 3)
            ],
            sender: SenderInfo(name: "DoorDash", initial: "D", email: nil),
            kid: nil,
            company: nil,
            store: "Chipotle",
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: true,
            expiresIn: "15 minutes",
            requiresSignature: nil,
            paymentAmount: 26.96,
            paymentDescription: "Food Delivery",
            value: nil,
            probability: nil,
            score: nil
        ))

        // Document review - review_approve
        cards.append(EmailCard(
            id: "doc1",
            type: .mail,
            state: .unseen,
            priority: .critical,
            hpa: "Review & Approve",
            timeAgo: "1h ago",
            title: "Q4 Budget Proposal - Urgent Approval Needed",
            summary: "Q4 budget proposal for $2.4M across all departments requires approval by 5 PM today. Review 24-page document covering engineering, marketing, sales, and operations spending.",

            aiGeneratedSummary: """
            **Actions:**
            • Review and approve $2.4M budget by **EOD today**

            **Why:**
            Q4 department budget requires your sign-off.

            **Context:**
            • Total: $2.4M across all departments
            • 24-page document attached
            """,

            body: "URGENT: Q4 Budget Proposal Review\n\nFrom: Finance Department\nTo: Department Heads\nSubject: Q4 Budget Approval Required - EOD Deadline\n\nAttached is the Q4 2024 budget proposal that requires your review and approval.\n\nBudget Summary:\nTotal Requested: $2.4M\n- Engineering: $950K (headcount + infrastructure)\n- Marketing: $520K (campaigns + tools)\n- Sales: $430K (travel + commissions)\n- Operations: $340K (facilities + systems)\n- HR: $160K (recruiting + training)\n\nKey Items:\n1. Engineering: 3 senior hires starting Q4\n2. Marketing: Major product launch campaign\n3. Sales: Annual conference sponsorships\n\nDeadline: Today, 5:00 PM PST\n\nPlease review the attached 24-page budget document and approve via the finance portal.\n\nQuestions? Contact Michael Chen, CFO\nmchen@company.com",
            htmlBody: nil,
            metaCTA: "Swipe Right: Review & Approve",
            intent: "business.document.approval",
            intentConfidence: 0.98,
            suggestedActions: [
                EmailAction(actionId: "review_approve", displayName: "Review & Approve", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "view_document", displayName: "View Document", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "delegate", displayName: "Delegate", actionType: .inApp, isPrimary: false, priority: 3)
            ],
            sender: SenderInfo(name: "Finance Dept", initial: "F", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: true,
            expiresIn: "Today",
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // Spreadsheet review - view_spreadsheet
        cards.append(EmailCard(
            id: "sheet1",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "Review Spreadsheet",
            timeAgo: "3h ago",
            title: "October Department Spending Report",
            summary: "October spending report shows $87,340 spent (8.1% under budget). Review detailed breakdown by November 5 - YTD spending at $856,200.",

            aiGeneratedSummary: """
            **Actions:**
            • Review October spending report by **November 5**

            **Why:**
            Monthly expense breakdown ready for your review.

            **Context:**
            • Spent: $87,340 (8.1% under budget)
            • YTD spending: $856,200
            """,

            body: "October Spending Report Available\n\nYour department's October spending report is ready for review.\n\nKey Metrics:\n- Total Spent: $87,340\n- Budget: $95,000\n- Variance: -$7,660 (8.1% under budget)\n- YTD Spending: $856,200\n\nTop Categories:\n1. Payroll: $65,000 (74%)\n2. Software/Tools: $12,400 (14%)\n3. Travel: $5,200 (6%)\n4. Office Supplies: $2,800 (3%)\n5. Other: $1,940 (3%)\n\nNotable Items:\n- New software subscriptions added\n- Conference travel under budget\n- Headcount remained stable\n\nPlease review the detailed spreadsheet and flag any discrepancies.\n\nNext Steps:\n- Review by November 5th\n- Submit comments if needed\n- Approve for final reconciliation\n\nFinance Team",
            htmlBody: nil,
            metaCTA: "Swipe Right: Review Spreadsheet",
            intent: "business.spreadsheet.review",
            intentConfidence: 0.96,
            suggestedActions: [
                EmailAction(actionId: "view_spreadsheet", displayName: "Review Spreadsheet", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "download_report", displayName: "Download Excel", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "reply", displayName: "Add Comments", actionType: .inApp, isPrimary: false, priority: 3)
            ],
            sender: SenderInfo(name: "Finance", initial: "F", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // Healthcare - view_results
        cards.append(EmailCard(
            id: "health1",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "View Results",
            timeAgo: "1h ago",
            title: "Lab Results Ready - Annual Physical",
            summary: "Annual physical lab results from October 18 are ready. All tests within normal ranges - Dr. Martinez reviewed and added notes to your chart.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            Lab results from October 18 physical now available.

            **Context:**
            • All results within normal ranges
            • Dr. Martinez added notes to chart
            """,

            body: "Your Lab Results Are Ready\n\nDear Patient,\n\nThe results from your recent lab work (October 18, 2024) are now available in your patient portal.\n\nTests Completed:\n- Complete Blood Count (CBC)\n- Comprehensive Metabolic Panel\n- Lipid Panel\n- Thyroid Function (TSH)\n- Vitamin D Level\n\nResults Summary:\nAll results are within normal ranges. Dr. Martinez has reviewed your labs and added notes to your chart.\n\nNext Steps:\n- Review your results online\n- Read Dr. Martinez's notes\n- Schedule follow-up if needed\n\nYour next annual physical is recommended in 12 months (October 2025).\n\nAccess Results:\nLog in to your Kaiser Permanente patient portal\nPatient ID: KP-8392847\n\nQuestions? Call (415) 555-0100\n\nKaiser Permanente\nSan Francisco Medical Center",
            htmlBody: nil,
            metaCTA: "Swipe Right: View Results",
            intent: "healthcare.results.available",
            intentConfidence: 0.99,
            suggestedActions: [
                EmailAction(actionId: "view_results", displayName: "View Results", actionType: .goTo, isPrimary: true, priority: 1, context: ["resultsUrl": "https://healthy.kaiserpermanente.org/results"]),
                EmailAction(actionId: "schedule_followup", displayName: "Schedule Follow-up", actionType: .goTo, isPrimary: false, priority: 2, context: ["schedulingUrl": "https://healthy.kaiserpermanente.org/schedule"]),
                EmailAction(actionId: "download_report", displayName: "Download PDF", actionType: .inApp, isPrimary: false, priority: 3)
            ],
            sender: SenderInfo(name: "Kaiser Permanente", initial: "K", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // CRM routing - route_crm
        cards.append(EmailCard(
            id: "crm1",
            type: .mail,
            state: .unseen,
            priority: .critical,
            hpa: "Route to CRM",
            timeAgo: "10m ago",
            title: "🔥 Hot Lead: Enterprise Customer Inquiry",
            summary: "GlobalCorp VP requesting enterprise demo for 5,000-user deployment worth $485K ARR. Lead score 95/100 - schedule discovery call within 24 hours.",

            aiGeneratedSummary: """
            **Actions:**
            • Route to CRM and schedule discovery call within **24 hours**

            **Why:**
            Fortune 500 company inquiring about 5,000-user enterprise plan.

            **Context:**
            • Deal value: $485K ARR
            • Lead score: 95/100 (HOT)
            • Decision timeline: 6 weeks
            """,

            body: "INBOUND LEAD - Immediate Attention Required\n\nFrom: Jennifer Williams <jennifer.williams@globalcorp.com>\nCompany: GlobalCorp International\nTitle: VP of Engineering\nCompany Size: 12,000 employees\nLead Score: 95/100 (HOT)\n\nInquiry:\n\"Hi, we're currently evaluating enterprise solutions for our engineering org. We need a platform that can support 5,000+ users with advanced security features including SSO, SAML, and audit logging.\n\nWe're in active vendor evaluation mode and need to make a decision by end of Q4. Can someone from your enterprise sales team reach out ASAP?\n\nTimeline is critical - we're looking to deploy by January 2025.\n\nBest,\nJennifer Williams\nVP Engineering, GlobalCorp\"\n\nLead Intelligence:\n- Company Revenue: $8B annually\n- Current Stack: Using competitors (unhappy)\n- Budget Authority: Confirmed ($500K+ budget)\n- Decision Timeline: 6 weeks\n- Competition: Evaluating 2 other vendors\n\nEstimated Deal Value: $485,000 ARR\nWin Probability: 72%\n\nRECOMMENDED ACTIONS:\n1. Route to Enterprise Sales Team\n2. Assign to Sarah Chen (VP Enterprise Sales)\n3. Schedule discovery call within 24 hours\n4. Prepare enterprise security deck",
            htmlBody: nil,
            metaCTA: "Swipe Right: Route to CRM",
            intent: "sales.lead.inbound.hot",
            intentConfidence: 1.0,
            suggestedActions: [
                EmailAction(actionId: "route_crm", displayName: "Route to CRM", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "assign_rep", displayName: "Assign to Sarah", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "schedule_meeting", displayName: "Schedule Call", actionType: .inApp, isPrimary: false, priority: 3)
            ],
            sender: SenderInfo(name: "Jennifer Williams", initial: "J", email: "jennifer.williams@globalcorp.com"),
            kid: nil,
            company: CompanyInfo(name: "GlobalCorp", initials: "GC"),
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: true,
            expiresIn: "24 hours",
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: "$485K",
            probability: 72,
            score: 95
        ))

        // Snooze/Archive - save_later
        cards.append(EmailCard(
            id: "snooze1",
            type: .mail,
            state: .unseen,
            priority: .low,
            hpa: "Save for Later",
            timeAgo: "1d ago",
            title: "FYI: New Feature Launch - Q1 2025",
            summary: "Product roadmap preview for Q1 2025 featuring AI search, real-time collaboration, and advanced analytics. Beta testing starts December - no immediate action needed.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            Preview of Q1 2025 feature launches.

            **Context:**
            • AI search, collaboration, analytics coming
            • Beta testing starts December
            • No immediate action required
            """,

            body: "Product Roadmap Preview - Q1 2025\n\nHi Team,\n\nWanted to give everyone an early heads up on major features launching in Q1 2025.\n\nUpcoming Features:\n\n1. AI-Powered Search (January)\n   - Natural language queries\n   - Smart filtering and suggestions\n   - 10x faster than current search\n\n2. Real-Time Collaboration (February)\n   - Multi-user editing\n   - Live cursors and presence\n   - Conflict resolution\n\n3. Advanced Analytics Dashboard (March)\n   - Custom reporting\n   - Data export capabilities\n   - Scheduled reports\n\nTimeline:\n- Beta testing: December 2024\n- Internal dogfooding: Late December\n- Public launch: Rolling out January-March\n\nNo action needed now - just wanted to keep everyone in the loop. We'll share more detailed specs and training materials as we get closer to launch.\n\nQuestions? Ping me on Slack.\n\nCheers,\nProduct Team",
            htmlBody: nil,
            metaCTA: "Swipe Right: Save for Later",
            intent: "information.fyi.roadmap",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "save_for_later", displayName: "Save for Later", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "archive", displayName: "Archive", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "add_reminder", displayName: "Remind in December", actionType: .inApp, isPrimary: false, priority: 3, context: ["reminderDate": "December 1"])
            ],
            sender: SenderInfo(name: "Product Team", initial: "P", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // MARK: - MISSING BACKEND ACTIONS (8 high-priority additions)

        // E-commerce: return_item
        cards.append(EmailCard(
            id: "ecom1",
            type: .ads,
            state: .unseen,
            priority: .high,
            hpa: "Return Item",
            timeAgo: "2h ago",
            title: "Easy Returns - 30 Day Window",
            summary: "Amazon order from October 10 eligible for free returns with 28 days remaining. Wireless headphones, USB-C cables, and phone case can be returned hassle-free.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            30-day return window available for recent order.

            **Context:**
            • Free returns within 28 days
            • Order #112-9384756-8472910
            """,
            body: """
            Easy Returns - Your Window is Still Open!

            Hi there,

            We want to make sure you're completely satisfied with your recent Amazon purchase. You still have time to return any items if they're not quite right.

            YOUR RETURN WINDOW

            Order Number: 112-9384756-8472910
            Order Date: October 10, 2025
            Return Deadline: November 9, 2025 (28 days remaining)

            WHAT YOU ORDERED

            1. Wireless Bluetooth Headphones - $79.99
            2. USB-C Charging Cable (3-pack) - $14.99
            3. Phone Case - Clear - $12.99

            WHY RETURN?

            Common reasons customers return:
            • Item doesn't fit or isn't the right size
            • Changed mind about the purchase
            • Found a better price elsewhere
            • Product doesn't meet expectations
            • Received wrong item or defective

            We make returns easy and FREE!

            HOW TO RETURN

            It's simple:
            1. Visit your Orders page
            2. Select the items to return
            3. Choose your reason
            4. Print your prepaid return label
            5. Drop off at UPS, Whole Foods, or Amazon Locker

            START RETURN: amazon.com/returns/112-9384756-8472910

            RETURN OPTIONS

            Drop-off Locations Near You:
            ✓ UPS Store (0.3 miles) - No box needed!
            ✓ Whole Foods Market (0.8 miles) - QR code return
            ✓ Amazon Locker (1.2 miles) - 24/7 access
            ✓ Kohl's (1.5 miles) - Returns accepted

            Most drop-off locations don't require a box - just bring the item!

            WHAT'S COVERED

            Free Returns Include:
            ✓ Prepaid return shipping label
            ✓ Full refund to original payment method
            ✓ No restocking fees
            ✓ No questions asked (within 30 days)

            Refund Processing:
            • Instant refund for drop-off returns
            • Full refund processed within 2 business days
            • Money returned to original payment method

            LOVE YOUR PURCHASE?

            If you're happy with your order, you don't need to do anything! We hope you're enjoying your new items.

            Want to buy it again? We've made it easy to reorder your favorites.

            BUY AGAIN: amazon.com/buy-again

            QUESTIONS?

            • Return policy: amazon.com/returns-policy
            • Track return status: amazon.com/returns
            • Need help? Contact us 24/7

            Customer Service:
            • Chat: amazon.com/contact-us
            • Phone: 1-888-280-4331

            Thanks for shopping with Amazon!

            Amazon Customer Service
            returns@amazon.com
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Return Item",
            intent: "e-commerce.return.eligible",
            intentConfidence: 0.97,
            suggestedActions: [
                EmailAction(actionId: "return_item", displayName: "Start Return", actionType: .goTo, isPrimary: true, priority: 1, context: ["orderNumber": "112-9384756-8472910", "returnUrl": "https://amazon.com/returns"]),
                EmailAction(actionId: "buy_again", displayName: "Buy Again", actionType: .goTo, isPrimary: false, priority: 2, context: ["productUrl": "https://amazon.com/buy-again/112-9384756-8472910"])
            ],
            sender: SenderInfo(name: "Amazon", initial: "A", email: nil),
            kid: nil,
            company: nil,
            store: "Amazon",
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: "28 days left",
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // E-commerce: buy_again
        cards.append(EmailCard(
            id: "ecom2",
            type: .ads,
            state: .unseen,
            priority: .medium,
            hpa: "Buy Again",
            timeAgo: "1d ago",
            title: "Loved It? Order Again with One Click",
            summary: "Blue Bottle Ethiopian coffee you love is ready to reorder at $16.99. One-click purchase with free Prime delivery or save 15% with Subscribe & Save.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            Favorite Starbucks coffee beans back in stock.

            **Context:**
            • Price: $16.99
            • One-click reorder available
            """,

            body: """
            Time to Restock? Your Favorite Coffee is Running Low!

            Hi Sarah,

            Based on your purchase history, you might be running low on Blue Bottle Coffee - Ethiopian Natural. Would you like to order again?

            YOUR FAVORITE

            Blue Bottle Coffee - Ethiopian Natural (12 oz)
            Price: $16.99
            Last Ordered: September 25, 2025 (30 days ago)

            Why You'll Love It:
            ⭐⭐⭐⭐⭐ You rated this 5 stars!
            "Best coffee I've had - fruity and smooth!"

            REORDER NOW - ONE CLICK

            No need to search or add to cart. Just click below and we'll ship it to you with your saved preferences.

            BUY AGAIN: amazon.com/buy-again/blue-bottle-ethiopian

            DELIVERY OPTIONS

            • FREE delivery by Tuesday (Prime)
            • Same-day delivery available ($3.99)
            • Subscribe & Save: Get 15% off ($14.44) + never run out

            Subscribe & Save Benefits:
            ✓ Save 15% on every delivery
            ✓ Free shipping always
            ✓ Flexible schedule (choose frequency)
            ✓ Cancel anytime, no commitments

            CUSTOMERS ALSO BOUGHT

            People who bought this coffee also love:
            • Blue Bottle Three Africas Blend - $17.99
            • Lavazza Super Crema Espresso - $21.99
            • Coffee Pour Over Dripper Set - $24.99

            Never run out again! Set up Subscribe & Save and get your favorite coffee delivered automatically.

            SETUP SUBSCRIPTION: amazon.com/subscribe-save

            Happy brewing!

            Amazon Shopping
            shop@amazon.com
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Buy Again",
            intent: "e-commerce.reorder.suggestion",
            intentConfidence: 0.89,
            suggestedActions: [
                EmailAction(actionId: "buy_again", displayName: "Buy Again", actionType: .goTo, isPrimary: true, priority: 1, context: ["orderNumber": "987654", "productUrl": "https://target.com/buy-again"]),
                EmailAction(actionId: "view_product", displayName: "View Product", actionType: .goTo, isPrimary: false, priority: 2, context: ["productUrl": "https://target.com/product/starbucks-coffee"])
            ],
            sender: SenderInfo(name: "Target", initial: "T", email: nil),
            kid: nil,
            company: nil,
            store: "Target",
            airline: nil,
            productImageUrl: "https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400",
            brandName: "Starbucks",
            originalPrice: 16.99,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // Healthcare: check_in_appointment
        cards.append(EmailCard(
            id: "health2",
            type: .mail,
            state: .unseen,
            priority: .critical,
            hpa: "Check In",
            timeAgo: "3h ago",
            title: "Appointment Tomorrow at 2:00 PM",
            summary: "Annual physical with Dr. Martinez tomorrow at 2:00 PM at Kaiser San Francisco. Check in online now to complete questionnaires and skip the waiting room line.",

            aiGeneratedSummary: """
            **Actions:**
            • Check in online for appointment **tomorrow at 2:00 PM**

            **Why:**
            Annual physical with Dr. Martinez scheduled.

            **Context:**
            • Kaiser San Francisco Medical Center
            • Online check-in saves time
            """,
            body: """
            Appointment Reminder Tomorrow

            Hi Sarah,

            This is a reminder about your upcoming appointment.

            APPOINTMENT DETAILS

            Date: Tomorrow, October 26, 2025
            Time: 2:00 PM
            Provider: Dr. Emily Martinez, MD
            Department: Primary Care
            Location: Kaiser San Francisco Medical Center, 2425 Geary Blvd

            Reason: Annual Physical Exam

            CHECK IN ONLINE NOW

            Save time at the clinic! Check in online before you arrive:
            • Complete health questionnaires
            • Update insurance information
            • Review medications
            • Skip the waiting room line

            CHECK IN: kaiserpermanente.org/checkin

            PREPARE FOR YOUR VISIT

            Please bring:
            ✓ Photo ID and insurance card
            ✓ List of current medications
            ✓ Questions for your doctor

            Arrive 15 minutes early if you haven't checked in online.

            NEED TO RESCHEDULE?

            Cancel or reschedule: kaiserpermanente.org/appointments
            Call: (415) 833-2000

            Cancellation policy: 24 hours notice required

            We look forward to seeing you!

            Kaiser Permanente
            San Francisco Medical Center
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Check In",
            intent: "healthcare.appointment.reminder",
            intentConfidence: 1.0,
            suggestedActions: [
                EmailAction(actionId: "check_in_appointment", displayName: "Check In", actionType: .goTo, isPrimary: true, priority: 1, context: ["checkInUrl": "https://kp.org/checkin/APT-2938475"]),
                EmailAction(actionId: "get_directions", displayName: "Get Directions", actionType: .goTo, isPrimary: false, priority: 2, context: ["location": "Kaiser San Francisco Medical Center", "mapsUrl": "https://maps.google.com/?q=Kaiser+San+Francisco+Medical+Center"]),
                EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 3)
            ],
            sender: SenderInfo(name: "Kaiser Permanente", initial: "K", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: true,
            expiresIn: "Tomorrow",
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // Healthcare: view_pickup_details
        cards.append(EmailCard(
            id: "health3",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "View Pickup Details",
            timeAgo: "1h ago",
            title: "Prescription Ready for Pickup",
            summary: "Lisinopril 10mg prescription ready at CVS Market Street. $12.50 copay - drive-thru available, open 8 AM to 10 PM, held for 10 days.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            Prescription ready for pickup at CVS.

            **Context:**
            • Rx #RX-847392
            • Location: 845 Market St, 8 AM - 10 PM
            • Copay: $12.50
            """,
            body: """
            Your Prescription is Ready for Pickup

            Hi Sarah,

            Good news! Your prescription is ready at CVS Pharmacy.

            PRESCRIPTION DETAILS

            Medication: Lisinopril 10mg (30-day supply)
            Prescription #: RX-847392
            Prescribed by: Dr. Martinez
            Copay: $12.50

            PICKUP LOCATION

            CVS Pharmacy #2847
            845 Market Street
            San Francisco, CA 94103
            Phone: (415) 555-0147

            Store Hours:
            Monday-Friday: 8:00 AM - 10:00 PM
            Saturday-Sunday: 9:00 AM - 9:00 PM
            Pharmacy closes 30 minutes before store

            READY FOR PICKUP

            Your prescription is waiting at the pharmacy counter. Please bring:
            ✓ Photo ID
            ✓ Insurance card (if applicable)
            ✓ Payment for $12.50 copay

            We'll hold your prescription for 10 days. After that, it will be returned to stock.

            DRIVE-THRU AVAILABLE

            Skip the line! Use our drive-thru pharmacy window for quick pickup.

            QUESTIONS?

            • Pharmacy: (415) 555-0147
            • Refill online: cvs.com/prescriptions
            • Auto-refill: cvs.com/auto-refill

            CVS Pharmacy
            Caring for you and your family
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: View Pickup Details",
            intent: "healthcare.prescription.ready",
            intentConfidence: 0.99,
            suggestedActions: [
                EmailAction(actionId: "view_pickup_details", displayName: "View Pickup Details", actionType: .inApp, isPrimary: true, priority: 1, context: ["rxNumber": "RX-847392", "pharmacy": "CVS Pharmacy", "address": "845 Market St, San Francisco", "hours": "8 AM - 10 PM"]),
                EmailAction(actionId: "get_directions", displayName: "Get Directions", actionType: .goTo, isPrimary: false, priority: 2, context: ["location": "CVS Pharmacy, 845 Market St, San Francisco", "mapsUrl": "https://maps.google.com/?q=CVS+Pharmacy+845+Market+St+San+Francisco"])
            ],
            sender: SenderInfo(name: "CVS Pharmacy", initial: "C", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: 12.50,
            paymentDescription: "Prescription copay",
            value: nil,
            probability: nil,
            score: nil
        ))

        // Support: view_ticket
        cards.append(EmailCard(
            id: "support1",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "View Ticket",
            timeAgo: "30m ago",
            title: "Support Ticket #12345 - In Progress",
            summary: "Support ticket for account access issue is being investigated by Marcus Johnson. 2FA settings being reset - new setup instructions coming within 2 hours.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            Support team working on your ticket.

            **Context:**
            • Ticket #12345 in progress
            • Can add details or reply
            """,
            body: """
            Support Ticket Update: Investigation in Progress

            Hi Sarah,

            We wanted to update you on your support ticket.

            TICKET INFORMATION

            Ticket #: 12345
            Subject: Cannot access account after password reset
            Status: In Progress
            Priority: High
            Assigned to: Marcus Johnson, Senior Support Engineer

            UPDATE FROM SUPPORT

            We've begun investigating your account access issue. Our senior engineer has identified the problem and is working on a solution.

            What we've found:
            • Your password reset was successful
            • Two-factor authentication is causing the login issue
            • We're resetting your 2FA settings

            Next Steps:
            1. We'll email you new 2FA setup instructions within 2 hours
            2. Follow the setup guide to reconfigure authentication
            3. Try logging in with your new password

            ESTIMATED RESOLUTION

            We expect to resolve this within 2-3 hours. You'll receive an email as soon as we've completed the fix.

            NEED TO ADD MORE INFORMATION?

            If you have additional details about the issue, reply to this email or update your ticket.

            VIEW TICKET: support.company.com/ticket/12345

            We appreciate your patience!

            Support Team
            support@company.com
            Ticket #12345
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: View Ticket",
            intent: "support.ticket.update",
            intentConfidence: 0.98,
            suggestedActions: [
                EmailAction(actionId: "view_ticket", displayName: "View Ticket", actionType: .goTo, isPrimary: true, priority: 1, context: ["ticketUrl": "https://support.zendesk.com/ticket/12345"]),
                EmailAction(actionId: "reply_to_ticket", displayName: "Reply", actionType: .inApp, isPrimary: false, priority: 2, context: ["ticketId": "12345"])
            ],
            sender: SenderInfo(name: "Customer Support", initial: "C", email: nil),
            kid: nil,
            company: CompanyInfo(name: "Zendesk", initials: "Z"),
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // Feedback: write_review
        cards.append(EmailCard(
            id: "review1",
            type: .ads,
            state: .unseen,
            priority: .medium,
            hpa: "Write Review",
            timeAgo: "2d ago",
            title: "How Was Your Recent Purchase?",
            summary: "Best Buy requesting review of Sony WH-1000XM5 headphones purchased October 15. Quick star rating or detailed review - earn 5 rewards points.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            Request to review Sony WH-1000XM5 headphones purchase.

            **Context:**
            • Optional feedback
            • Quick rating available
            """,
            body: """
            How Was Your Recent Purchase?

            Hi Sarah,

            We hope you're enjoying your recent order! We'd love to hear what you think.

            YOUR ORDER

            Sony WH-1000XM5 Headphones
            Ordered: October 15, 2025
            Delivered: October 18, 2025

            WRITE A REVIEW

            Your feedback helps other customers make informed decisions and helps us improve our service.

            Quick Rating (30 seconds):
            ⭐⭐⭐⭐⭐ Tap to rate

            Or write a detailed review:
            • Share your experience
            • Include photos
            • Help the community

            WRITE REVIEW: bestbuy.com/review/sony-wh1000xm5

            WHY REVIEWS MATTER

            ✓ Help other shoppers decide
            ✓ Give feedback to manufacturers
            ✓ Earn Best Buy rewards points (5 points per review!)

            Thank you for shopping with us!

            Best Buy
            Customer Reviews Team
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Write Review",
            intent: "feedback.review.request",
            intentConfidence: 0.94,
            suggestedActions: [
                EmailAction(actionId: "write_review", displayName: "Write Review", actionType: .inApp, isPrimary: true, priority: 1, context: ["productName": "Sony WH-1000XM5 Headphones", "url": "https://bestbuy.com/review/sony-wh1000xm5"]),
                EmailAction(actionId: "rate_product", displayName: "Quick Rate", actionType: .inApp, isPrimary: false, priority: 2, context: ["productName": "Sony WH-1000XM5"])
            ],
            sender: SenderInfo(name: "Best Buy", initial: "B", email: nil),
            kid: nil,
            company: nil,
            store: "Best Buy",
            airline: nil,
            productImageUrl: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400",
            brandName: "Sony",
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // Events: rsvp_yes
        cards.append(EmailCard(
            id: "event1",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "RSVP",
            timeAgo: "4h ago",
            title: "Team Happy Hour - Friday 5 PM",
            summary: "Team happy hour invitation this Friday at 5 PM at The Corner Office Bar & Grill. First 2 drinks on company plus appetizers - RSVP by Wednesday.",

            aiGeneratedSummary: """
            **Actions:**
            • RSVP by **Wednesday** for happy hour

            **Why:**
            Team happy hour invitation for Friday at The Local Tap.

            **Context:**
            • Drinks and appetizers
            • Friday 5 PM
            """,
            body: """
            You're Invited: Team Happy Hour This Friday!

            Hey Sarah!

            Join us this Friday for our monthly team happy hour! It's a great chance to unwind and catch up with everyone.

            EVENT DETAILS

            What: Team Happy Hour
            When: Friday, October 27, 2025 at 5:00 PM
            Where: The Corner Office Bar & Grill
            Address: 1415 Folsom Street, San Francisco

            What's Included:
            • Drinks (first 2 on the company!)
            • Appetizers
            • Good conversation

            RSVP

            Let us know if you can make it so we can reserve enough space.

            RSVP YES: company.com/events/happy-hour-oct27

            Hope to see you there!

            The Social Committee
            social@company.com
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: RSVP Yes",
            intent: "event.invitation.social",
            intentConfidence: 0.91,
            suggestedActions: [
                EmailAction(actionId: "rsvp_yes", displayName: "RSVP Yes", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "rsvp_no", displayName: "RSVP No", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 3)
            ],
            sender: SenderInfo(name: "Team Lead", initial: "T", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: "RSVP by Wednesday",
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // Travel: manage_booking
        cards.append(EmailCard(
            id: "travel4",
            type: .ads,
            state: .unseen,
            priority: .medium,
            hpa: "Manage Booking",
            timeAgo: "1d ago",
            title: "Hotel Reservation Confirmed - Nov 15-18",
            summary: "Marriott Marquis New York reservation confirmed November 15-18 for 3 nights. King room with city view on 21st floor - total $669.33 including taxes.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            Hyatt Regency San Francisco reservation confirmed.

            **Context:**
            • Dates: November 15-18 (3 nights)
            • Total: $567
            """,
            body: """
            Hotel Reservation Confirmed - Marriott Marquis NYC

            Hi Sarah,

            Your hotel reservation at Marriott Marquis New York is confirmed!

            RESERVATION DETAILS

            Hotel: Marriott Marquis
            Location: 1535 Broadway, Times Square, New York, NY
            Check-in: Friday, November 15, 2025 (3:00 PM)
            Check-out: Monday, November 18, 2025 (11:00 AM)
            Nights: 3
            Room: King Bed Room - City View (21st floor)

            Confirmation: MM-NYC-847392

            TOTAL COST

            Room Rate: $189/night x 3 nights = $567.00
            Taxes & Fees: $102.33
            Total: $669.33

            Payment: Visa ending in 4242

            WHAT'S INCLUDED

            ✓ Free Wi-Fi
            ✓ Fitness center access
            ✓ Business center
            ✓ 24-hour room service

            MANAGE BOOKING

            • View details: marriott.com/reservations/MM-NYC-847392
            • Modify reservation: marriott.com/modify
            • Cancel: Free cancellation until Nov 13

            Looking forward to your stay!

            Marriott Marquis New York
            reservations@marriott.com
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Manage Booking",
            intent: "travel.hotel.confirmation",
            intentConfidence: 0.96,
            suggestedActions: [
                EmailAction(actionId: "manage_booking", displayName: "Manage Booking", actionType: .goTo, isPrimary: true, priority: 1, context: ["confirmationCode": "HYT-948372", "bookingUrl": "https://hyatt.com/booking/HYT-948372"]),
                EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 2),
                EmailAction(actionId: "get_directions", displayName: "Get Directions", actionType: .goTo, isPrimary: false, priority: 3, context: ["location": "Hyatt Regency San Francisco", "mapsUrl": "https://maps.google.com/?q=Hyatt+Regency+San+Francisco"])
            ],
            sender: SenderInfo(name: "Hyatt", initial: "H", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: 567.00,
            paymentDescription: "3 nights",
            value: nil,
            probability: nil,
            score: nil
        ))

        // Support: contact_support
        cards.append(EmailCard(
            id: "support2",
            type: .mail,
            state: .unseen,
            priority: .medium,
            hpa: "Contact Support",
            timeAgo: "4h ago",
            title: "Package Delivery Issue - Need Help?",
            summary: "Amazon package delayed at shipping facility due to high volume. Kitchen mixer and bowls rescheduled for delivery October 27 - contact support if needed.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            Package delivery encountered an issue.

            **Context:**
            • Support available to help
            • Can track or contact Amazon
            """,
            body: """
            Delivery Delayed - We're Here to Help

            Hi Sarah,

            We're sorry - your package is running late. We're working to get it to you as soon as possible.

            ORDER DETAILS

            Order #: 112-8473625-2847392
            Expected Delivery: October 25 (today)
            Current Status: Delayed - rescheduled for Oct 27

            Package Contents:
            • Kitchen Mixer - $199.99
            • Mixing Bowl Set - $24.99

            WHAT HAPPENED

            Your package experienced a delay at our shipping facility due to high volume. We've rescheduled delivery for October 27th.

            WHAT WE'RE DOING

            • Prioritizing your package for next available delivery
            • Monitoring shipment closely
            • Will update you if status changes

            YOUR OPTIONS

            1. Wait for rescheduled delivery (Oct 27)
            2. Cancel order and get full refund
            3. Contact support for assistance

            TRACK PACKAGE: amazon.com/track/112-8473625-2847392

            We sincerely apologize for the inconvenience.

            Amazon Customer Service
            support@amazon.com
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Contact Support",
            intent: "e-commerce.delivery.issue",
            intentConfidence: 0.92,
            suggestedActions: [
                EmailAction(actionId: "contact_support", displayName: "Contact Support", actionType: .goTo, isPrimary: true, priority: 1, context: ["supportUrl": "https://amazon.com/support"]),
                EmailAction(actionId: "track_package", displayName: "Track Package", actionType: .inApp, isPrimary: false, priority: 2, context: ["url": "https://amazon.com/track", "trackingNumber": "Unknown", "carrier": "Amazon"])
            ],
            sender: SenderInfo(name: "Amazon", initial: "A", email: nil),
            kid: nil,
            company: nil,
            store: "Amazon",
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // Generic: quick_reply
        cards.append(EmailCard(
            id: "generic1",
            type: .mail,
            state: .unseen,
            priority: .high,
            hpa: "Quick Reply",
            timeAgo: "1h ago",
            title: "Quick Question About Tomorrow's Meeting",
            summary: "Mike asking if you can review Q3 presentation deck before Friday's board meeting. Need feedback on financial projections section - takes 15-20 minutes.",

            aiGeneratedSummary: """
            **Actions:**
            • Reply with slide deck before **tomorrow's** call

            **Why:**
            Jessica needs slide deck for tomorrow's meeting.

            **Context:**
            • Quick response needed
            • Simple question
            """,
            body: """
            Quick Question from Mike

            Hey Sarah,

            Hope you're having a good day! Quick question for you.

            Are you free to review the Q3 presentation deck before the board meeting on Friday? I'd love to get your feedback on the financial projections section.

            Should only take 15-20 minutes to review. Let me know if you can take a look today or tomorrow.

            Thanks!

            Mike
            CFO
            mike@company.com
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Quick Reply",
            intent: "communication.question.simple",
            intentConfidence: 0.88,
            suggestedActions: [
                EmailAction(actionId: "quick_reply", displayName: "Quick Reply", actionType: .inApp, isPrimary: true, priority: 1),
                EmailAction(actionId: "save_for_later", displayName: "Save for Later", actionType: .inApp, isPrimary: false, priority: 2)
            ],
            sender: SenderInfo(name: "Jessica Martinez", initial: "J", email: "jessica@company.com"),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: nil,
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // Dining: modify_reservation
        cards.append(EmailCard(
            id: "rest2",
            type: .mail,
            state: .unseen,
            priority: .medium,
            hpa: "Modify Reservation",
            timeAgo: "3h ago",
            title: "Reminder: Dinner Reservation Tonight at 8 PM",
            summary: "State Bird Provisions reservation reminder for tomorrow at 8 PM for party of 4. Arrive within 15 minutes or table may be released - can modify up to 2 hours before.",

            aiGeneratedSummary: """
            **Actions:**
            None

            **Why:**
            Reminder for tonight's dinner at Nobu San Francisco.

            **Context:**
            • Time: 8 PM
            • Party of 4
            • Can modify if needed
            """,
            body: """
            Reservation Reminder: Dinner Tomorrow at 8 PM

            Hi Sarah,

            This is a friendly reminder about your upcoming reservation.

            RESERVATION DETAILS

            Restaurant: State Bird Provisions
            Date: Tomorrow, October 26, 2025
            Time: 8:00 PM
            Party Size: 4 guests
            Confirmation: SBP-2025-8473

            Location:
            1529 Fillmore Street
            San Francisco, CA 94115
            (415) 795-1272

            PLEASE NOTE

            • Arrive within 15 minutes of reservation time or table may be released
            • Casual dress code
            • Full menu available
            • Street parking available nearby

            NEED TO CHANGE?

            You can modify or cancel your reservation up to 2 hours before.

            MODIFY: opentable.com/modify/SBP-2025-8473
            CANCEL: opentable.com/cancel/SBP-2025-8473

            Cancellation Policy: Cancel at least 2 hours in advance to avoid $25/person fee

            We look forward to serving you!

            State Bird Provisions
            reservations@statebird.com
            """,

            htmlBody: nil,
            metaCTA: "Swipe Right: Modify Reservation",
            intent: "dining.reservation.reminder",
            intentConfidence: 0.94,
            suggestedActions: [
                EmailAction(actionId: "view_reservation", displayName: "View Reservation", actionType: .goTo, isPrimary: true, priority: 1, context: ["reservationUrl": "https://opentable.com/r/nobu-sf", "confirmationCode": "NOBU-8473"]),
                EmailAction(actionId: "modify_reservation", displayName: "Modify Reservation", actionType: .goTo, isPrimary: false, priority: 2, context: ["confirmationCode": "NOBU-8473"]),
                EmailAction(actionId: "add_to_calendar", displayName: "Add to Calendar", actionType: .inApp, isPrimary: false, priority: 3)
            ],
            sender: SenderInfo(name: "OpenTable", initial: "O", email: nil),
            kid: nil,
            company: nil,
            store: nil,
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: false,
            expiresIn: "Tonight",
            requiresSignature: nil,
            paymentAmount: nil,
            paymentDescription: nil,
            value: nil,
            probability: nil,
            score: nil
        ))

        // Delivery: contact_driver
        cards.append(EmailCard(
            id: "food2",
            type: .ads,
            state: .unseen,
            priority: .high,
            hpa: "Contact Driver",
            timeAgo: "10m ago",
            title: "Your Uber Eats Order is 2 Minutes Away",
            summary: "Your Chipotle order with Ahmed is arriving in 2 minutes. Chicken burrito bowl and sides - watch for black Honda Civic, total $24.50.",

            aiGeneratedSummary: """
            **Actions:**
            • Meet driver arriving in **2 minutes**

            **Why:**
            Ahmed arriving with Chipotle order.

            **Context:**
            • Total: $24.50
            • Can contact driver if needed
            """,

            body: """
            Your DoorDash Order is Arriving Soon!

            Hi Sarah,

            Great news! Your food is on the way and should arrive in about 10 minutes.

            ORDER DETAILS

            Restaurant: Chipotle Mexican Grill
            Order #: DD-8473625
            Estimated Arrival: 10 minutes
            Delivery Address: 456 Market St, Apt 12B

            YOUR ORDER

            • Chicken Burrito Bowl x 1
            • Chips & Guacamole x 1
            • Bottled Water x 1

            Subtotal: $18.50
            Delivery Fee: $3.99
            Tip: $2.01
            Total: $24.50

            TRACK YOUR DELIVERY

            Your driver Marcus is on the way!
            • Vehicle: Silver Toyota Camry
            • License: 7ABC123
            • Phone: (415) 555-0189

            TRACK LIVE: doordash.com/track/DD-8473625

            DELIVERY INSTRUCTIONS

            "Leave at door, ring doorbell"

            Need to contact your driver? Tap the link above to call or message.

            Enjoy your meal!

            DoorDash
            support@doordash.com
            """,
            htmlBody: nil,
            metaCTA: "Swipe Right: Track Delivery",
            intent: "food-delivery.arriving.soon",
            intentConfidence: 0.99,
            suggestedActions: [
                EmailAction(actionId: "track_delivery", displayName: "Track Delivery", actionType: .goTo, isPrimary: true, priority: 1, context: ["trackingUrl": "https://ubereats.com/track/UE-9283745", "driverName": "Ahmed K.", "eta": "2 minutes"]),
                EmailAction(actionId: "contact_driver", displayName: "Contact Driver", actionType: .inApp, isPrimary: false, priority: 2, context: ["driverName": "Ahmed K.", "vehicle": "Black Honda Civic", "phone": "(415) 555-0199", "rating": "4.9"])
            ],
            sender: SenderInfo(name: "Uber Eats", initial: "U", email: nil),
            kid: nil,
            company: nil,
            store: "Chipotle",
            airline: nil,
            productImageUrl: nil,
            brandName: nil,
            originalPrice: nil,
            salePrice: nil,
            discount: nil,
            urgent: true,
            expiresIn: "2 minutes",
            requiresSignature: nil,
            paymentAmount: 24.50,
            paymentDescription: "Food Delivery",
            value: nil,
            probability: nil,
            score: nil
        ))


        return cards
    }
}
