"""Seed script: creates 30 Little Rock users & businesses with skills via the deployed API."""

import requests
import uuid
import time

BASE_URL = "https://app-swapai-backend.azurewebsites.net"
TIMEOUT = 60  # longer timeout for skill creation (involves embeddings)

USERS = [
    # =========================================================================
    # BUSINESSES (8)
    # =========================================================================
    {
        "full_name": "Hog Wash Supercenter",
        "username": "hogwash_lr",
        "email": "hogwash@example.com",
        "bio": "Little Rock's premier auto detailing & repair shop. We keep your ride looking fresh.",
        "skills_to_offer": "Car detailing, paint touch-ups, window tinting",
        "services_needed": "Marketing, online booking system",
        "account_type": "business",
        "skills": [
            {"title": "Professional Car Detailing", "description": "Full interior and exterior detailing services. We handle paint correction, ceramic coating, and premium washes to keep your car showroom-ready.", "category": "Automotive", "difficulty": "Intermediate", "estimated_hours": 3, "delivery": "In Person", "tags": ["detailing", "auto", "cars"], "deliverables": ["Full detail service", "Paint touch-up", "Interior deep clean"]},
            {"title": "Window Tinting Service", "description": "Professional window tinting for cars and trucks. UV protection, heat reduction, and privacy — all done right.", "category": "Automotive", "difficulty": "Intermediate", "estimated_hours": 2, "delivery": "In Person", "tags": ["tinting", "auto", "windows"], "deliverables": ["Window tint installation", "UV protection", "Warranty info"]},
        ],
    },
    {
        "full_name": "Community Bakery",
        "username": "community_bakery",
        "email": "communitybakery@example.com",
        "bio": "A Little Rock staple since 1947. We bake fresh bread, pastries, and custom cakes daily.",
        "skills_to_offer": "Custom cakes, catering, baked goods",
        "services_needed": "Website, photography",
        "account_type": "business",
        "skills": [
            {"title": "Custom Cakes & Catering", "description": "Beautiful custom cakes for any occasion — weddings, birthdays, graduations. We also cater events with fresh pastries, sandwiches, and more.", "category": "Cooking", "difficulty": "Intermediate", "estimated_hours": 5, "delivery": "In Person", "tags": ["cakes", "catering", "bakery"], "deliverables": ["Custom cake", "Catering menu", "Tasting session"]},
        ],
    },
    {
        "full_name": "The Root Cafe",
        "username": "therootcafe",
        "email": "therootcafe@example.com",
        "bio": "Farm-to-table restaurant in Little Rock's SoMa district. Good food, good people, good vibes.",
        "skills_to_offer": "Meals, catering, event hosting",
        "services_needed": "Online ordering system",
        "account_type": "business",
        "skills": [
            {"title": "Farm-to-Table Catering & Events", "description": "Locally sourced catering for your next event. We handle everything from menu planning to setup, with seasonal ingredients from Arkansas farms.", "category": "Cooking", "difficulty": "Intermediate", "estimated_hours": 6, "delivery": "In Person", "tags": ["catering", "farm-to-table", "events"], "deliverables": ["Custom menu", "Event setup", "Local sourcing"]},
        ],
    },
    {
        "full_name": "Rock City Outfitters",
        "username": "rockcity_outfitters",
        "email": "rockcity@example.com",
        "bio": "Local Little Rock clothing brand. Representing the city with original designs and streetwear.",
        "skills_to_offer": "Apparel design, merchandise, screen printing",
        "services_needed": "Influencer marketing",
        "account_type": "business",
        "skills": [
            {"title": "Custom Apparel & Merch Design", "description": "We design and produce custom streetwear, band merch, and branded apparel. Screen printing and embroidery available.", "category": "Design", "difficulty": "Intermediate", "estimated_hours": 4, "delivery": "Hybrid", "tags": ["apparel", "merch", "streetwear"], "deliverables": ["Design mockups", "Sample prints", "Bulk order"]},
        ],
    },
    {
        "full_name": "Blue Cake Company",
        "username": "bluecake_co",
        "email": "bluecake@example.com",
        "bio": "Little Rock's favorite dessert shop. Cupcakes, cake pops, and custom dessert tables.",
        "skills_to_offer": "Desserts, custom cupcakes, catering",
        "services_needed": "Social media growth",
        "account_type": "business",
        "skills": [
            {"title": "Custom Desserts & Dessert Catering", "description": "Stunning dessert tables and custom cupcakes for any event. We specialize in creative flavors and beautiful presentation.", "category": "Cooking", "difficulty": "Beginner", "estimated_hours": 4, "delivery": "In Person", "tags": ["desserts", "cupcakes", "catering"], "deliverables": ["Custom dessert order", "Dessert table setup", "Flavor consultation"]},
        ],
    },
    {
        "full_name": "Arkansas Graphics",
        "username": "arkansas_graphics",
        "email": "arkgraphics@example.com",
        "bio": "Full-service print and design shop in Little Rock. Logos, flyers, banners, and brand packages.",
        "skills_to_offer": "Logo design, flyers, branding, print services",
        "services_needed": "Website optimization, SEO",
        "account_type": "business",
        "skills": [
            {"title": "Logo & Brand Identity Design", "description": "Professional logo design and complete brand packages. We create cohesive visual identities for businesses — logos, business cards, letterheads, and brand guidelines.", "category": "Design", "difficulty": "Intermediate", "estimated_hours": 8, "delivery": "Hybrid", "tags": ["logo", "branding", "print"], "deliverables": ["Logo files", "Brand guide", "Business cards"]},
            {"title": "Print Design — Flyers & Banners", "description": "Eye-catching flyers, posters, and banners for events and promotions. Design and print, all in-house.", "category": "Design", "difficulty": "Beginner", "estimated_hours": 3, "delivery": "Hybrid", "tags": ["flyers", "print", "banners"], "deliverables": ["Design proofs", "Print-ready files", "Printed materials"]},
        ],
    },
    {
        "full_name": "Natural State Smoothies",
        "username": "naturalstate_smoothies",
        "email": "nssmoothies@example.com",
        "bio": "Fresh smoothies and cold-pressed juices in Little Rock. Fuel your body the natural way.",
        "skills_to_offer": "Smoothies, juice blends, catering",
        "services_needed": "Mobile ordering system",
        "account_type": "business",
        "skills": [
            {"title": "Smoothie & Juice Catering", "description": "Fresh smoothie bar for your event or office. We bring the blenders, ingredients, and good vibes. Custom menus available.", "category": "Cooking", "difficulty": "Beginner", "estimated_hours": 3, "delivery": "In Person", "tags": ["smoothies", "juice", "catering"], "deliverables": ["Custom menu", "On-site smoothie bar", "Ingredient sourcing"]},
        ],
    },
    {
        "full_name": "Philander Smith College Bookstore",
        "username": "psc_bookstore",
        "email": "pscbookstore@example.com",
        "bio": "Campus bookstore at Philander Smith College. Textbooks, school merch, and HBCU pride.",
        "skills_to_offer": "Books, school merchandise, campus resources",
        "services_needed": "Inventory management system",
        "account_type": "business",
        "skills": [
            {"title": "Campus Merchandise & School Supplies", "description": "Official Philander Smith merchandise — hoodies, tees, accessories, and textbooks. We also support campus events with custom gear.", "category": "Business", "difficulty": "Beginner", "estimated_hours": 2, "delivery": "In Person", "tags": ["merchandise", "college", "hbcu"], "deliverables": ["Merch catalog", "Custom orders", "Event gear"]},
        ],
    },
    # =========================================================================
    # INDIVIDUAL USERS (22)
    # =========================================================================
    {
        "full_name": "Otito Udedibor",
        "username": "otito_dev",
        "email": "otito.udedibor@example.com",
        "bio": "Frontend developer in Little Rock. I build clean, responsive web interfaces and love great UI.",
        "skills_to_offer": "UI design, web interfaces, frontend development",
        "services_needed": "Fitness training",
        "account_type": "person",
        "skills": [
            {"title": "UI Design & Web Interfaces", "description": "I design and build modern, responsive web interfaces. From wireframes to polished UIs — clean code and pixel-perfect results.", "category": "Design", "difficulty": "Intermediate", "estimated_hours": 10, "delivery": "Remote Only", "tags": ["ui", "frontend", "web-design"], "deliverables": ["UI mockups", "Responsive code", "Design system"]},
            {"title": "Frontend Development (React/Flutter)", "description": "Build interactive frontends with React or Flutter. Component architecture, state management, and API integration.", "category": "Programming", "difficulty": "Intermediate", "estimated_hours": 12, "delivery": "Remote Only", "tags": ["react", "flutter", "frontend"], "deliverables": ["Working prototype", "Source code", "Documentation"]},
        ],
    },
    {
        "full_name": "Tyler Brooks",
        "username": "tyler_webdev",
        "email": "tyler.brooks@example.com",
        "bio": "Web developer based in Little Rock. I build websites that look great and work even better.",
        "skills_to_offer": "Website development, WordPress, landing pages",
        "services_needed": "Food, catering",
        "account_type": "person",
        "skills": [
            {"title": "Website Development", "description": "Custom websites from scratch or WordPress builds. Responsive design, SEO basics, and fast load times included.", "category": "Programming", "difficulty": "Intermediate", "estimated_hours": 10, "delivery": "Remote Only", "tags": ["web-dev", "wordpress", "websites"], "deliverables": ["Live website", "Source files", "Hosting setup"]},
        ],
    },
    {
        "full_name": "Brandon Carter",
        "username": "brandon_apps",
        "email": "brandon.carter@example.com",
        "bio": "App developer in Little Rock. Building mobile solutions for local businesses and startups.",
        "skills_to_offer": "Mobile app development, iOS, Android",
        "services_needed": "Meals, food services",
        "account_type": "person",
        "skills": [
            {"title": "Mobile App Development", "description": "I build native and cross-platform mobile apps. From concept to App Store — clean UX and solid architecture.", "category": "Programming", "difficulty": "Advanced", "estimated_hours": 15, "delivery": "Remote Only", "tags": ["mobile", "ios", "android", "apps"], "deliverables": ["Working app", "Source code", "App Store submission"]},
        ],
    },
    {
        "full_name": "Ethan Mitchell",
        "username": "ethan_ui",
        "email": "ethan.mitchell@example.com",
        "bio": "UI designer crafting intuitive digital experiences. Based in Little Rock, working with clients everywhere.",
        "skills_to_offer": "Interface design, prototyping, Figma",
        "services_needed": "New clients, networking",
        "account_type": "person",
        "skills": [
            {"title": "Interface Design & Prototyping", "description": "Beautiful, functional interface designs in Figma. I create interactive prototypes that bring your product vision to life.", "category": "Design", "difficulty": "Intermediate", "estimated_hours": 8, "delivery": "Remote Only", "tags": ["ui", "figma", "prototyping"], "deliverables": ["Figma designs", "Interactive prototype", "Design specs"]},
        ],
    },
    {
        "full_name": "Caleb Turner",
        "username": "caleb_backend",
        "email": "caleb.turner@example.com",
        "bio": "Backend developer in Little Rock. APIs, databases, and server infrastructure are my thing.",
        "skills_to_offer": "APIs, backend systems, database design",
        "services_needed": "Exposure, marketing",
        "account_type": "person",
        "skills": [
            {"title": "Backend API Development", "description": "I build robust REST APIs and backend systems. Python, Node.js, PostgreSQL — scalable and well-documented.", "category": "Programming", "difficulty": "Advanced", "estimated_hours": 12, "delivery": "Remote Only", "tags": ["api", "backend", "python", "nodejs"], "deliverables": ["API endpoints", "Documentation", "Database schema"]},
        ],
    },
    {
        "full_name": "Jordan Hayes",
        "username": "jordan_data",
        "email": "jordan.hayes@example.com",
        "bio": "Data analyst turning numbers into actionable insights. Little Rock based, data driven.",
        "skills_to_offer": "Data analysis, dashboards, Excel, SQL",
        "services_needed": "Tutoring",
        "account_type": "person",
        "skills": [
            {"title": "Data Analysis & Dashboards", "description": "Turn your raw data into clear insights. I build dashboards, run analyses, and create reports that drive decisions.", "category": "Data Science", "difficulty": "Intermediate", "estimated_hours": 8, "delivery": "Remote Only", "tags": ["data", "analytics", "dashboards", "sql"], "deliverables": ["Dashboard", "Data report", "Analysis summary"]},
        ],
    },
    {
        "full_name": "Mason Scott",
        "username": "mason_social",
        "email": "mason.scott@example.com",
        "bio": "Social media manager growing brands in Little Rock and beyond. Instagram is my playground.",
        "skills_to_offer": "Instagram growth, social media management, content planning",
        "services_needed": "Desserts, catering",
        "account_type": "person",
        "skills": [
            {"title": "Instagram Growth & Management", "description": "Grow your Instagram the right way. Content strategy, hashtag research, Reels, engagement tactics, and monthly management.", "category": "Marketing", "difficulty": "Beginner", "estimated_hours": 5, "delivery": "Remote Only", "tags": ["instagram", "social-media", "growth"], "deliverables": ["Content calendar", "Hashtag strategy", "Growth report"]},
        ],
    },
    {
        "full_name": "Dylan Cooper",
        "username": "dylan_video",
        "email": "dylan.cooper@example.com",
        "bio": "Videographer and filmmaker in Little Rock. Telling stories through the lens.",
        "skills_to_offer": "Video production, editing, cinematography",
        "services_needed": "Clothing, merch",
        "account_type": "person",
        "skills": [
            {"title": "Video Production & Editing", "description": "Professional video production for businesses, events, and social media. Shooting, editing, color grading, and delivery.", "category": "Video Production", "difficulty": "Intermediate", "estimated_hours": 8, "delivery": "Hybrid", "tags": ["video", "editing", "cinematography"], "deliverables": ["Edited video", "Raw footage", "Social media cuts"]},
        ],
    },
    {
        "full_name": "Connor Bailey",
        "username": "connor_photo",
        "email": "connor.bailey@example.com",
        "bio": "Photographer capturing Little Rock's best moments. Portraits, events, and brand shoots.",
        "skills_to_offer": "Photography, portraits, event coverage",
        "services_needed": "New clients, exposure",
        "account_type": "person",
        "skills": [
            {"title": "Professional Photography", "description": "Portraits, headshots, events, and brand photography. I deliver polished, edited photos that tell your story.", "category": "Photography", "difficulty": "Intermediate", "estimated_hours": 4, "delivery": "In Person", "tags": ["photography", "portraits", "events"], "deliverables": ["Edited photos", "Digital gallery", "Print-ready files"]},
        ],
    },
    {
        "full_name": "Austin Jenkins",
        "username": "austin_content",
        "email": "austin.jenkins@example.com",
        "bio": "Content creator making TikToks and short-form videos. Little Rock's viral moment guy.",
        "skills_to_offer": "TikTok content, short-form video, social media",
        "services_needed": "Collaborations, networking",
        "account_type": "person",
        "skills": [
            {"title": "TikTok & Short-Form Content", "description": "Create scroll-stopping TikToks and Reels. I handle concept, filming, editing, and posting strategy.", "category": "Marketing", "difficulty": "Beginner", "estimated_hours": 4, "delivery": "Hybrid", "tags": ["tiktok", "reels", "content"], "deliverables": ["Video content", "Posting schedule", "Trend analysis"]},
        ],
    },
    {
        "full_name": "Ryan Walker",
        "username": "ryan_brand",
        "email": "ryan.walker@example.com",
        "bio": "Branding strategist helping Little Rock businesses stand out. Your brand is your story.",
        "skills_to_offer": "Brand identity, brand strategy, positioning",
        "services_needed": "Various services",
        "account_type": "person",
        "skills": [
            {"title": "Brand Strategy & Identity", "description": "Define your brand from the inside out. Mission, values, visual identity, and messaging that connects with your audience.", "category": "Marketing", "difficulty": "Intermediate", "estimated_hours": 10, "delivery": "Hybrid", "tags": ["branding", "strategy", "identity"], "deliverables": ["Brand strategy doc", "Visual identity", "Messaging guide"]},
        ],
    },
    {
        "full_name": "Ashley Parker",
        "username": "ashley_design",
        "email": "ashley.parker@example.com",
        "bio": "Graphic designer in Little Rock. Album covers, posters, and visual art that pops.",
        "skills_to_offer": "Graphic design, album covers, poster design",
        "services_needed": "Exposure, clients",
        "account_type": "person",
        "skills": [
            {"title": "Graphic Design & Album Covers", "description": "Custom graphic design for music, events, and brands. Album covers, posters, social media graphics — bold and creative.", "category": "Design", "difficulty": "Intermediate", "estimated_hours": 6, "delivery": "Remote Only", "tags": ["graphic-design", "album-art", "posters"], "deliverables": ["Design files", "Print-ready artwork", "Social media assets"]},
        ],
    },
    {
        "full_name": "Madison Collins",
        "username": "madison_brand",
        "email": "madison.collins@example.com",
        "bio": "Brand designer creating visual identities for Little Rock businesses and beyond.",
        "skills_to_offer": "Branding, visual identity, packaging design",
        "services_needed": "Clothing, apparel",
        "account_type": "person",
        "skills": [
            {"title": "Visual Branding & Packaging", "description": "Complete brand design — logos, packaging, labels, and brand guidelines. I make your product look premium.", "category": "Design", "difficulty": "Intermediate", "estimated_hours": 8, "delivery": "Remote Only", "tags": ["branding", "packaging", "design"], "deliverables": ["Logo suite", "Packaging mockups", "Brand guidelines"]},
        ],
    },
    {
        "full_name": "Chloe Bennett",
        "username": "chloe_ux",
        "email": "chloe.bennett@example.com",
        "bio": "UX designer passionate about user-centered design. Building my portfolio in Little Rock.",
        "skills_to_offer": "UX design, user research, wireframing",
        "services_needed": "Portfolio projects, collaborations",
        "account_type": "person",
        "skills": [
            {"title": "UX Design & User Research", "description": "User-centered design from research to prototype. Wireframes, user flows, usability testing, and polished deliverables.", "category": "Design", "difficulty": "Intermediate", "estimated_hours": 10, "delivery": "Remote Only", "tags": ["ux", "user-research", "wireframes"], "deliverables": ["Wireframes", "User flow diagrams", "Usability report"]},
        ],
    },
    {
        "full_name": "Hannah Foster",
        "username": "hannah_foodphoto",
        "email": "hannah.foster@example.com",
        "bio": "Food photographer making Little Rock restaurants look irresistible. Your food deserves great photos.",
        "skills_to_offer": "Food photography, product photography, editing",
        "services_needed": "Clients, restaurant connections",
        "account_type": "person",
        "skills": [
            {"title": "Food & Product Photography", "description": "Mouthwatering food photos and clean product shots. Styled, lit, and edited to make your brand shine on menus and social media.", "category": "Photography", "difficulty": "Intermediate", "estimated_hours": 4, "delivery": "In Person", "tags": ["food-photography", "product", "styling"], "deliverables": ["Edited photos", "Social media crops", "Menu-ready images"]},
        ],
    },
    {
        "full_name": "Emily Richardson",
        "username": "emily_tutor",
        "email": "emily.richardson@example.com",
        "bio": "Math tutor helping Little Rock students build confidence. All levels — algebra to calculus.",
        "skills_to_offer": "Math tutoring, test prep, academic coaching",
        "services_needed": "Marketing, social media",
        "account_type": "person",
        "skills": [
            {"title": "Math Tutoring — All Levels", "description": "Patient, clear math tutoring from algebra to calculus. I break down concepts so they actually click. Test prep and homework help included.", "category": "Languages", "difficulty": "Beginner", "estimated_hours": 6, "delivery": "Hybrid", "tags": ["math", "tutoring", "education"], "deliverables": ["Lesson plans", "Practice problems", "Progress tracking"]},
        ],
    },
    {
        "full_name": "Lauren Simmons",
        "username": "lauren_resume",
        "email": "lauren.simmons@example.com",
        "bio": "Resume coach and career advisor in Little Rock. Your resume should open doors — let me help.",
        "skills_to_offer": "Resume writing, LinkedIn optimization, interview prep",
        "services_needed": "Clients, marketing",
        "account_type": "person",
        "skills": [
            {"title": "Resume Writing & Career Coaching", "description": "Professional resume rewrites, LinkedIn makeovers, and interview coaching. I help you land the job you actually want.", "category": "Business", "difficulty": "Beginner", "estimated_hours": 3, "delivery": "Remote Only", "tags": ["resume", "career", "linkedin"], "deliverables": ["Polished resume", "LinkedIn profile", "Interview tips"]},
        ],
    },
    {
        "full_name": "Megan Sanders",
        "username": "megan_events",
        "email": "megan.sanders@example.com",
        "bio": "Event planner bringing Little Rock's celebrations to life. Weddings, parties, corporate events.",
        "skills_to_offer": "Event planning, coordination, vendor management",
        "services_needed": "Vendors, partnerships",
        "account_type": "person",
        "skills": [
            {"title": "Event Planning & Coordination", "description": "Full-service event planning — timelines, vendor coordination, decor, and day-of management. Stress-free events, guaranteed.", "category": "Business", "difficulty": "Intermediate", "estimated_hours": 10, "delivery": "In Person", "tags": ["events", "planning", "weddings"], "deliverables": ["Event timeline", "Vendor list", "Day-of coordination"]},
        ],
    },
    {
        "full_name": "Kayla Brooks",
        "username": "kayla_hair",
        "email": "kayla.brooks@example.com",
        "bio": "Hair stylist in Little Rock. Cuts, color, braids, and protective styles. Your hair, your crown.",
        "skills_to_offer": "Hair styling, braids, color, protective styles",
        "services_needed": "Branding, social media",
        "account_type": "person",
        "skills": [
            {"title": "Hair Styling & Braiding", "description": "Professional hair services — cuts, color, braids, twists, and protective styles. I work with all hair types and textures.", "category": "Fitness", "difficulty": "Intermediate", "estimated_hours": 3, "delivery": "In Person", "tags": ["hair", "braids", "styling"], "deliverables": ["Styling session", "Hair care tips", "Style consultation"]},
        ],
    },
    {
        "full_name": "Jessica Morgan",
        "username": "jessica_fit",
        "email": "jessica.morgan@example.com",
        "bio": "Certified fitness coach in Little Rock. Custom training programs that fit your life.",
        "skills_to_offer": "Personal training, workout plans, nutrition coaching",
        "services_needed": "Website, online presence",
        "account_type": "person",
        "skills": [
            {"title": "Personal Training & Fitness Plans", "description": "Custom workout programs designed around your goals and schedule. In-person or virtual sessions with accountability check-ins.", "category": "Fitness", "difficulty": "Beginner", "estimated_hours": 6, "delivery": "Hybrid", "tags": ["fitness", "training", "workouts"], "deliverables": ["Workout plan", "Nutrition guide", "Progress tracking"]},
        ],
    },
    {
        "full_name": "Brittany Hayes",
        "username": "brittany_nails",
        "email": "brittany.hayes@example.com",
        "bio": "Nail technician and nail artist in Little Rock. From classic sets to wild designs.",
        "skills_to_offer": "Nail services, nail art, manicures",
        "services_needed": "Marketing, social media growth",
        "account_type": "person",
        "skills": [
            {"title": "Nail Art & Manicure Services", "description": "Professional nail services — gel, acrylic, press-ons, and custom nail art. Clean, creative, and always on trend.", "category": "Design", "difficulty": "Beginner", "estimated_hours": 2, "delivery": "In Person", "tags": ["nails", "nail-art", "beauty"], "deliverables": ["Nail service", "Design consultation", "Aftercare guide"]},
        ],
    },
    {
        "full_name": "Olivia Carter",
        "username": "olivia_mua",
        "email": "olivia.carter@example.com",
        "bio": "Makeup artist in Little Rock. Bridal, editorial, and everyday glam. Making faces glow since 2019.",
        "skills_to_offer": "Makeup services, bridal makeup, editorial looks",
        "services_needed": "Clients, networking",
        "account_type": "person",
        "skills": [
            {"title": "Makeup Artistry", "description": "Professional makeup for weddings, photoshoots, events, and everyday glam. Skin prep, application, and long-lasting looks.", "category": "Design", "difficulty": "Intermediate", "estimated_hours": 2, "delivery": "In Person", "tags": ["makeup", "bridal", "beauty"], "deliverables": ["Makeup application", "Trial session", "Product recommendations"]},
        ],
    },
]


def seed():
    success = 0
    fail = 0

    for user in USERS:
        uid = f"seed_{uuid.uuid4().hex[:12]}"
        profile = {
            "uid": uid,
            "email": user["email"],
            "display_name": user["full_name"],
            "full_name": user["full_name"],
            "username": user["username"],
            "bio": user["bio"],
            "city": "Little Rock, AR",
            "timezone": "America/Chicago",
            "skills_to_offer": user["skills_to_offer"],
            "services_needed": user["services_needed"],
            "dm_open": True,
            "email_updates": False,
            "show_city": True,
            "account_type": user.get("account_type", "person"),
        }

        # Create profile
        resp = requests.post(f"{BASE_URL}/profiles/upsert", json=profile, timeout=TIMEOUT)
        if resp.status_code == 200:
            print(f"✓ Profile: {user['full_name']} ({uid})")
        else:
            print(f"✗ Profile FAILED: {user['full_name']} — {resp.status_code} {resp.text[:200]}")
            fail += 1
            continue

        # Post skills (with retry for 500s / timeouts)
        for skill in user["skills"]:
            for attempt in range(3):
                try:
                    resp = requests.post(f"{BASE_URL}/skills?uid={uid}", json=skill, timeout=TIMEOUT)
                    if resp.status_code == 200:
                        print(f"  ✓ Skill: {skill['title']}")
                        success += 1
                        break
                    elif resp.status_code >= 500 and attempt < 2:
                        print(f"  ⟳ Retry {attempt+1}: {skill['title']} — {resp.status_code}")
                        time.sleep(3)
                    else:
                        print(f"  ✗ Skill FAILED: {skill['title']} — {resp.status_code} {resp.text[:200]}")
                        fail += 1
                        break
                except requests.exceptions.Timeout:
                    if attempt < 2:
                        print(f"  ⟳ Timeout retry {attempt+1}: {skill['title']}")
                        time.sleep(3)
                    else:
                        print(f"  ✗ Skill TIMEOUT: {skill['title']}")
                        fail += 1

            time.sleep(1)  # pace between skills

    print(f"\nDone! Skills posted: {success}, Failures: {fail}")


if __name__ == "__main__":
    seed()
