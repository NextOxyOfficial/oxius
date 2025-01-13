from django.core.management.base import BaseCommand
from cities.models import Country, Region, City, Upazila


class Command(BaseCommand):
    help = 'Load district and upazila data into the database'

    def handle(self, *args, **kwargs):
        data = [
            {
                "name_eng": "Bangladesh",
                "name_ban": "বাংলাদেশ",
                "regions": [
                    {
                        "name_eng": "Chattogram",
                        "name_ban": "চট্টগ্রাম",
                        "cities": [
                            {
                                "name_eng": "Cumilla",
                                "name_ban": "কুমিল্লা",
                                "upazilas": [
                                    {"name_eng": "Debidwar", "name_ban": "দেবিদ্বার"},
                                    {"name_eng": "Barura", "name_ban": "বরুড়া"},
                                    {"name_eng": "Brahmanpara", "name_ban": "ব্রাহ্মণপাড়া"},
                                    {"name_eng": "Chandina", "name_ban": "চান্দিনা"},
                                    {"name_eng": "Chauddagram", "name_ban": "চৌদ্দগ্রাম"},
                                    {"name_eng": "Daudkandi Model", "name_ban": "দাউদকান্দি মডেল"},
                                    {"name_eng": "Homna", "name_ban": "হোমনা"},
                                    {"name_eng": "Laksam", "name_ban": "লাকসাম"},
                                    {"name_eng": "Muradnagar", "name_ban": "মুরাদনগর"},
                                    {"name_eng": "Nangalkot", "name_ban": "নাঙ্গলকোট"},
                                    {"name_eng": "Cumilla Sadar", "name_ban": "কুমিল্লা সদর"},
                                    {"name_eng": "Meghna", "name_ban": "মেঘনা"},
                                    {"name_eng": "Monohargonj", "name_ban": "মনোহরগঞ্জ"},
                                    {"name_eng": "Sadar South", "name_ban": "সদর দক্ষিণ"},
                                    {"name_eng": "Titas", "name_ban": "তিতাস"},
                                    {"name_eng": "Burichang", "name_ban": "বুড়িচং"},
                                    {"name_eng": "Bipara", "name_ban": "বিপাড়া"}
                                ]
                            },
                            {
                                "name_eng": "Feni",
                                "name_ban": "ফেনী",
                                "upazilas": [
                                    {"name_eng": "Chhagalnaiya", "name_ban": "ছাগলনাইয়া"},
                                    {"name_eng": "Feni Model", "name_ban": "ফেনী মডেল"},
                                    {"name_eng": "Sonagazi", "name_ban": "সোনাগাজী"},
                                    {"name_eng": "Fulgazi", "name_ban": "ফুলগাজী"},
                                    {"name_eng": "Parshuram", "name_ban": "পরশুরাম"},
                                    {"name_eng": "Daganbhuiyan", "name_ban": "দাগনভূঞা"}
                                ]
                            },
                            {
                                "name_eng": "Brahmanbaria",
                                "name_ban": "ব্রাহ্মণবাড়িয়া",
                                "upazilas": [
                                    {"name_eng": "Brahmanbaria Sadar", "name_ban": "ব্রাহ্মণবাড়িয়া সদর"},
                                    {"name_eng": "Kasba", "name_ban": "কসবা"},
                                    {"name_eng": "Nasirnagar", "name_ban": "নাসিরনগর"},
                                    {"name_eng": "Sarail", "name_ban": "সরাইল"},
                                    {"name_eng": "Ashuganj", "name_ban": "আশুগঞ্জ"},
                                    {"name_eng": "Akhaura", "name_ban": "আখাউড়া"},
                                    {"name_eng": "Nabinagar", "name_ban": "নবীনগর"},
                                    {"name_eng": "Bancharampur", "name_ban": "বাঞ্ছারামপুর"},
                                    {"name_eng": "Bijoynagar", "name_ban": "বিজয়নগর"}
                                ]
                            },
                            {
                                "name_eng": "Rangamati",
                                "name_ban": "রাঙ্গামাটি",
                                "upazilas": [
                                    
                                    {"name_eng": "Kaptai", "name_ban": "কাপ্তাই"},
                                    {"name_eng": "Kawkhali", "name_ban": "কাউখালী"},
                                    {"name_eng": "Baghaichari", "name_ban": "বাঘাইছড়ি"},
                                    {"name_eng": "Barkal", "name_ban": "বরকল"},
                                    {"name_eng": "Langadu", "name_ban": "লংগদু"},
                                    {"name_eng": "Rajasthali", "name_ban": "রাজস্থলী"},
                                    {"name_eng": "Belaichari", "name_ban": "বিলাইছড়ি"},
                                    {"name_eng": "Juraichari", "name_ban": "জুরাছড়ি"},
                                    {"name_eng": "Naniarchar", "name_ban": "নানিয়ারচর"},
                                    {"name_eng": "Kotowali", "name_ban": "কোতওয়ালি"},
                                    {"name_eng": "Chandroghona", "name_ban": "চন্দ্রঘনা"},
                                    {"name_eng": "Sazek", "name_ban": "সাজেক"},
                                ]
                            },
                            {
                                "name_eng": "Noakhali",
                                "name_ban": "নোয়াখালী",
                                "upazilas": [
                                    {"name_eng": "Charjabbar", "name_ban": "চারজব্বার"},
                                    {"name_eng": "Companiganj", "name_ban": "কোম্পানীগঞ্জ"},
                                    {"name_eng": "Begumganj", "name_ban": "বেগমগঞ্জ"},
                                    {"name_eng": "Hatia", "name_ban": "হাতিয়া"},
                                    {"name_eng": "Shudharam", "name_ban": "সুধারাম"},
                                    {"name_eng": "Kabirhat", "name_ban": "কবিরহাট"},
                                    {"name_eng": "Senbug", "name_ban": "সেনবাগ"},
                                    {"name_eng": "Chatkhil", "name_ban": "চাটখিল"},
                                    {"name_eng": "Sonaimuri", "name_ban": "সোনাইমুড়ী"}
                                ]
                            },
                            {
                                "name_eng": "Chandpur",
                                "name_ban": "চাঁদপুর",
                                "upazilas": [
                                    {"name_eng": "Haimchar", "name_ban": "হাইমচর"},
                                    {"name_eng": "Kachua", "name_ban": "কচুয়া"},
                                    {"name_eng": "Shahrasti", "name_ban": "শাহরাস্তি"},
                                    {"name_eng": "Chandpur", "name_ban": "চাঁদপুর"},
                                    {"name_eng": "Matlab South", "name_ban": "মতলব দক্ষিন"},
                                    {"name_eng": "Matlab North", "name_ban": "মতলব উত্তর"},
                                    {"name_eng": "Hajiganj", "name_ban": "হাজীগঞ্জ"},
                                    {"name_eng": "Faridgonj", "name_ban": "ফরিদগঞ্জ"}
                                ]
                            },
                            {
                                "name_eng": "Lakshmipur",
                                "name_ban": "লক্ষ্মীপুর",
                                "upazilas": [
                                    {"name_eng": "Lakshmipur Sadar", "name_ban": "লক্ষ্মীপুর সদর"},
                                    {"name_eng": "Kamalnagar", "name_ban": "কমলনগর"},
                                    {"name_eng": "Raipur", "name_ban": "রায়পুর"},
                                    {"name_eng": "Ramgati", "name_ban": "রামগতি"},
                                    {"name_eng": "Ramganj", "name_ban": "রামগঞ্জ"}
                                ]
                            },
                            {
                                "name_eng": "Chattogram",
                                "name_ban": "চট্টগ্রাম",
                                "upazilas": [
                                    {"name_eng": "Rangunia", "name_ban": "রাঙ্গুনিয়া"},
                                    {"name_eng": "Sitakunda", "name_ban": "সীতাকুন্ড"},
                                    {"name_eng": "Mirsharai", "name_ban": "মীরসরাই"},
                                    {"name_eng": "Patiya", "name_ban": "পটিয়া"},
                                    {"name_eng": "Sandwip", "name_ban": "সন্দ্বীপ"},
                                    {"name_eng": "Banshkhali", "name_ban": "বাঁশখালী"},
                                    {"name_eng": "Boalkhali", "name_ban": "বোয়ালখালী"},
                                    {"name_eng": "Anwara", "name_ban": "আনোয়ারা"},
                                    {"name_eng": "Chandanaish", "name_ban": "চন্দনাইশ"},
                                    {"name_eng": "Satkania", "name_ban": "সাতকানিয়া"},
                                    {"name_eng": "Lohagara", "name_ban": "লোহাগাড়া"},
                                    {"name_eng": "Hathazari", "name_ban": "হাটহাজারী"},
                                    {"name_eng": "Fatikchhari", "name_ban": "ফটিকছড়ি"},
                                    {"name_eng": "Raozan", "name_ban": "রাউজান"},
                                    {"name_eng": "Vujpur", "name_ban": "ভুজপুর"},
                                    {"name_eng": "Zorargonj", "name_ban": "জোরারগঞ্জ"},
                                ]
                            },
                            {
                                "name_eng": "Coxsbazar",
                                "name_ban": "কক্সবাজার",
                                "upazilas": [
                                    {"name_eng": "Coxsbazar", "name_ban": "কক্সবাজার"},
                                    {"name_eng": "Chakaria", "name_ban": "চকরিয়া"},
                                    {"name_eng": "Kutubdia", "name_ban": "কুতুবদিয়া"},
                                    {"name_eng": "Ukhiya", "name_ban": "উখিয়া"},
                                    {"name_eng": "Moheshkhali", "name_ban": "মহেশখালী"},
                                    {"name_eng": "Pekua", "name_ban": "পেকুয়া"},
                                    {"name_eng": "Ramu", "name_ban": "রামু"},
                                    {"name_eng": "Teknaf", "name_ban": "টেকনাফ"}
                                ]
                            },
                            {
                                "name_eng": "Khagrachhari",
                                "name_ban": "খাগড়াছড়ি",
                                "upazilas": [
                                    {"name_eng": "Khagrasori Sadar", "name_ban": "খাগড়াছড়ি সদর"},
                                    {"name_eng": "Dighinala", "name_ban": "দিঘীনালা"},
                                    {"name_eng": "Panchari", "name_ban": "পানছড়ি"},
                                    {"name_eng": "Laxmichhari", "name_ban": "লক্ষীছড়ি"},
                                    {"name_eng": "Mohalchari", "name_ban": "মহালছড়ি"},
                                    {"name_eng": "Manikchari", "name_ban": "মানিকছড়ি"},
                                    {"name_eng": "Ramgor", "name_ban": "রামগড়"},
                                    {"name_eng": "Matiranga", "name_ban": "মাটিরাঙ্গা"},
                                    {"name_eng": "Guimara", "name_ban": "গুইমারা"}
                                ]
                            },
                            {
                                "name_eng": "Bandarban",
                                "name_ban": "বান্দরবান",
                                "upazilas": [
                                    {"name_eng": "Bandarban Sadar", "name_ban": "বান্দরবান সদর"},
                                    {"name_eng": "Alikadam", "name_ban": "আলীকদম"},
                                    {"name_eng": "Naikhongchhari", "name_ban": "নাইক্ষ্যংছড়ি"},
                                    {"name_eng": "Rowangchhari", "name_ban": "রোয়াংছড়ি"},
                                    {"name_eng": "Lama", "name_ban": "লামা"},
                                    {"name_eng": "Ruma", "name_ban": "রুমা"},
                                    {"name_eng": "Thanchi", "name_ban": "থানচি"}
                                ]
                            }
                        ]
                    },
                    {
                        "name_eng": "Rajshahi",
                        "name_ban": "রাজশাহী",
                        "cities": [
                            {
                                "name_eng": "Sirajganj",
                                "name_ban": "সিরাজগঞ্জ",
                                "upazilas": [
                                    {"name_eng": "Belkuchi", "name_ban": "বেলকুচি"},
                                    {"name_eng": "Chauhali", "name_ban": "চৌহালি"},
                                    {"name_eng": "Kamarkhand", "name_ban": "কামারখন্দ"},
                                    {"name_eng": "Kazipur", "name_ban": "কাজীপুর"},
                                    {"name_eng": "Raigonj", "name_ban": "রায়গঞ্জ"},
                                    {"name_eng": "Shahjadpur", "name_ban": "শাহজাদপুর"},
                                    {"name_eng": "Sirajganj Sadar", "name_ban": "সিরাজগঞ্জ সদর"},
                                    {"name_eng": "Tarash", "name_ban": "তাড়াশ"},
                                    {"name_eng": "Ullapara", "name_ban": "উল্লাপাড়া"},
                                    {"name_eng": "Enayetpur", "name_ban": "এনায়েতপুর"},
                                    {"name_eng": "Salanga", "name_ban": "সলঙ্গা"},
                                    {"name_eng": "Bangabandhu Setu West", "name_ban": "বঙ্গবন্ধু সেতু পশ্চিম"},
                                ]
                            },
                            {
                                "name_eng": "Pabna",
                                "name_ban": "পাবনা",
                                "upazilas": [
                                    {"name_eng": "Sujanagar", "name_ban": "সুজানগর"},
                                    {"name_eng": "Ishurdi", "name_ban": "ঈশ্বরদী"},
                                    {"name_eng": "Bhangura", "name_ban": "ভাঙ্গুড়া"},
                                    {"name_eng": "Pabna Sadar", "name_ban": "পাবনা সদর"},
                                    {"name_eng": "Bera", "name_ban": "বেড়া"},
                                    {"name_eng": "Atghoria", "name_ban": "আটঘরিয়া"},
                                    {"name_eng": "Chatmohar", "name_ban": "চাটমোহর"},
                                    {"name_eng": "Santhia", "name_ban": "সাঁথিয়া"},
                                    {"name_eng": "Faridpur", "name_ban": "ফরিদপুর"},
                                    {"name_eng": "Ataeikula", "name_ban": "আতাইকুলা"},
                                    {"name_eng": "Aminpur", "name_ban": "আমিনপুর"},
                                ]
                            },
                            {
                                "name_eng": "Bogura",
                                "name_ban": "বগুড়া",
                                "upazilas": [
                                    {"name_eng": "Kahaloo", "name_ban": "কাহালু"},
                                    {"name_eng": "Bogra Sadar", "name_ban": "বগুড়া সদর"},
                                    {"name_eng": "Shariakandi", "name_ban": "সারিয়াকান্দি"},
                                    {"name_eng": "Shajahanpur", "name_ban": "শাজাহানপুর"},
                                    {"name_eng": "Dupchanchia", "name_ban": "দুপচাচিঁয়া"},
                                    {"name_eng": "Adamdighi", "name_ban": "আদমদিঘি"},
                                    {"name_eng": "Nondigram", "name_ban": "নন্দিগ্রাম"},
                                    {"name_eng": "Sonatala", "name_ban": "সোনাতলা"},
                                    {"name_eng": "Dhunot", "name_ban": "ধুনট"},
                                    {"name_eng": "Gabtali", "name_ban": "গাবতলী"},
                                    {"name_eng": "Sherpur", "name_ban": "শেরপুর"},
                                    {"name_eng": "Shibganj", "name_ban": "শিবগঞ্জ"}
                                ]
                            },
                            
                            {
                                "name_eng": "Natore",
                                "name_ban": "নাটোর",
                                "upazilas": [
                                    {"name_eng": "Natore Sadar", "name_ban": "নাটোর সদর"},
                                    {"name_eng": "Singra", "name_ban": "সিংড়া"},
                                    {"name_eng": "Baraigram", "name_ban": "বড়াইগ্রাম"},
                                    {"name_eng": "Bagatipara", "name_ban": "বাগাতিপাড়া"},
                                    {"name_eng": "Lalpur", "name_ban": "লালপুর"},
                                    {"name_eng": "Gurudaspur", "name_ban": "গুরুদাসপুর"},
                                    {"name_eng": "Naldanga", "name_ban": "নলডাঙ্গা"}
                                ]
                            },
                            {
                                "name_eng": "Joypurhat",
                                "name_ban": "জয়পুরহাট",
                                "upazilas": [
                                    {"name_eng": "Akkelpur", "name_ban": "আক্কেলপুর"},
                                    {"name_eng": "Kalai", "name_ban": "কালাই"},
                                    {"name_eng": "Khetlal", "name_ban": "ক্ষেতলাল"},
                                    {"name_eng": "Panchbibi", "name_ban": "পাঁচবিবি"},
                                    {"name_eng": "Joypurhat", "name_ban": "জয়পুরহাট"}
                                ]
                            },
                            {
                                "name_eng": "Chapainawabganj",
                                "name_ban": "চাঁপাইনবাবগঞ্জ",
                                "upazilas": [
                                    {"name_eng": "Nababganj", "name_ban": "নবাবগঞ্জ"},
                                    {"name_eng": "Gomostapur", "name_ban": "গোমস্তাপুর"},
                                    {"name_eng": "Nachol", "name_ban": "নাচোল"},
                                    {"name_eng": "Bholahat", "name_ban": "ভোলাহাট"},
                                    {"name_eng": "Shibganj", "name_ban": "শিবগঞ্জ"}
                                ]
                            },
                            {
                                "name_eng": "Naogaon",
                                "name_ban": "নওগাঁ",
                                "upazilas": [
                                    {"name_eng": "Mohadevpur", "name_ban": "মহাদেবপুর"},
                                    {"name_eng": "Badalgachi", "name_ban": "বদলগাছী"},
                                    {"name_eng": "Patnitala", "name_ban": "পত্নিতলা"},
                                    {"name_eng": "Dhamoirhat", "name_ban": "ধামইরহাট"},
                                    {"name_eng": "Niamatpur", "name_ban": "নিয়ামতপুর"},
                                    {"name_eng": "Manda", "name_ban": "মান্দা"},
                                    {"name_eng": "Atrai", "name_ban": "আত্রাই"},
                                    {"name_eng": "Raninagar", "name_ban": "রাণীনগর"},
                                    {"name_eng": "Naogaon Sadar", "name_ban": "নওগাঁ সদর"},
                                    {"name_eng": "Porsha", "name_ban": "পোরশা"},
                                    {"name_eng": "Sapahar", "name_ban": "সাপাহার"},
                                ]
                            }
                        ]
                    },
                    {
                        "name_eng": "Khulna",
                        "name_ban": "খুলনা",
                        "cities": [
                            {
                                "name_eng": "Jashore",
                                "name_ban": "যশোর",
                                "upazilas": [
                                    {"name_eng": "Manirampur", "name_ban": "মণিরামপুর"},
                                    {"name_eng": "Abhaynagar", "name_ban": "অভয়নগর"},
                                    {"name_eng": "Bagherpara", "name_ban": "বাঘারপাড়া"},
                                    {"name_eng": "Chougachha", "name_ban": "চৌগাছা"},
                                    {"name_eng": "Jhikargacha", "name_ban": "ঝিকরগাছা"},
                                    {"name_eng": "Keshabpur", "name_ban": "কেশবপুর"},
                                    {"name_eng": "Sharsha", "name_ban": "শার্শা"},
                                    {"name_eng": "Kotowali", "name_ban": "কোতওয়ালি"},
                                    {"name_eng": "Benapol Port", "name_ban": "বেনাপল পোর্ট"},
                                ]
                            },
                            {
                                "name_eng": "Satkhira",
                                "name_ban": "সাতক্ষীরা",
                                "upazilas": [
                                    {"name_eng": "Assasuni", "name_ban": "আশাশুনি"},
                                    {"name_eng": "Debhata", "name_ban": "দেবহাটা"},
                                    {"name_eng": "Kalaroa", "name_ban": "কলারোয়া"},
                                    {"name_eng": "Satkhira Sadar", "name_ban": "সাতক্ষীরা সদর"},
                                    {"name_eng": "Shyamnagar", "name_ban": "শ্যামনগর"},
                                    {"name_eng": "Tala", "name_ban": "তালা"},
                                    {"name_eng": "Kaliganj", "name_ban": "কালিগঞ্জ"},
                                    {"name_eng": "Patkelghata", "name_ban": "পাটকেলঘাটা"},
                                ]
                            },
                            {
                                "name_eng": "Meherpur",
                                "name_ban": "মেহেরপুর",
                                "upazilas": [
                                    {"name_eng": "Mujibnagar", "name_ban": "মুজিবনগর"},
                                    {"name_eng": "Meherpur Sadar", "name_ban": "মেহেরপুর সদর"},
                                    {"name_eng": "Gangni", "name_ban": "গাংনী"}
                                ]
                            },
                            {
                                "name_eng": "Narail",
                                "name_ban": "নড়াইল",
                                "upazilas": [
                                    {"name_eng": "Narail Sadar", "name_ban": "নড়াইল সদর"},
                                    {"name_eng": "Lohagara", "name_ban": "লোহাগড়া"},
                                    {"name_eng": "Kalia", "name_ban": "কালিয়া"}
                                ]
                            },
                            {
                                "name_eng": "Chuadanga",
                                "name_ban": "চুয়াডাঙ্গা",
                                "upazilas": [
                                    {"name_eng": "Chuadanga Sadar", "name_ban": "চুয়াডাঙ্গা সদর"},
                                    {"name_eng": "Alamdanga", "name_ban": "আলমডাঙ্গা"},
                                    {"name_eng": "Damurhuda", "name_ban": "দামুড়হুদা"},
                                    {"name_eng": "Jibannagar", "name_ban": "জীবননগর"}
                                ]
                            },
                            {
                                "name_eng": "Kushtia",
                                "name_ban": "কুষ্টিয়া",
                                "upazilas": [
                                    {"name_eng": "Kushtia Sadar", "name_ban": "কুষ্টিয়া সদর"},
                                    {"name_eng": "Kumarkhali", "name_ban": "কুমারখালী"},
                                    {"name_eng": "Khoksa", "name_ban": "খোকসা"},
                                    {"name_eng": "Mirpur", "name_ban": "মিরপুর"},
                                    {"name_eng": "Daulatpur", "name_ban": "দৌলতপুর"},
                                    {"name_eng": "Bheramara", "name_ban": "ভেড়ামারা"},
                                    {"name_eng": "Islamic University", "name_ban": "ইসলামি বিশ্ববিদ্যালয়"},
                                ]
                            },
                            {
                                "name_eng": "Magura",
                                "name_ban": "মাগুরা",
                                "upazilas": [
                                    {"name_eng": "Shalikha", "name_ban": "শালিখা"},
                                    {"name_eng": "Sreepur", "name_ban": "শ্রীপুর"},
                                    {"name_eng": "Magura Sadar", "name_ban": "মাগুরা সদর"},
                                    {"name_eng": "Mohammadpur", "name_ban": "মহম্মদপুর"}
                                ]
                            },
                            {
                                "name_eng": "Khulna",
                                "name_ban": "খুলনা",
                                "upazilas": [
                                    {"name_eng": "Paikgasa", "name_ban": "পাইকগাছা"},
                                    {"name_eng": "Fultola", "name_ban": "ফুলতলা"},
                                    {"name_eng": "Digholia", "name_ban": "দিঘলিয়া"},
                                    {"name_eng": "Rupsha", "name_ban": "রূপসা"},
                                    {"name_eng": "Terokhada", "name_ban": "তেরখাদা"},
                                    {"name_eng": "Dumuria", "name_ban": "ডুমুরিয়া"},
                                    {"name_eng": "Botiaghata", "name_ban": "বটিয়াঘাটা"},
                                    {"name_eng": "Dakop", "name_ban": "দাকোপ"},
                                    {"name_eng": "Koyra", "name_ban": "কয়রা"}
                                ]
                            },
                            {
                                "name_eng": "Bagerhat",
                                "name_ban": "বাগেরহাট",
                                "upazilas": [
                                    {"name_eng": "Fakirhat", "name_ban": "ফকিরহাট"},
                                    {"name_eng": "Bagerhat", "name_ban": "বাগেরহাট"},
                                    {"name_eng": "Mollahat", "name_ban": "মোল্লাহাট"},
                                    {"name_eng": "Morrelganj Sharankhola", "name_ban": "মোড়েলগঞ্জ শরণখোলা"},
                                    {"name_eng": "Rampal", "name_ban": "রামপাল"},
                                    {"name_eng": "Kachua", "name_ban": "কচুয়া"},
                                    {"name_eng": "Mongla", "name_ban": "মোংলা"},
                                    {"name_eng": "Chitalmari", "name_ban": "চিতলমারী"}
                                ]
                            },
                            {
                                "name_eng": "Jhenaidah",
                                "name_ban": "ঝিনাইদহ",
                                "upazilas": [
                                    {"name_eng": "Jhenaidah", "name_ban": "ঝিনাইদহ"},
                                    {"name_eng": "Shailkupa", "name_ban": "শৈলকুপা"},
                                    {"name_eng": "Harinakundu", "name_ban": "হরিণাকুন্ডু"},
                                    {"name_eng": "Kaliganj", "name_ban": "কালীগঞ্জ"},
                                    {"name_eng": "Kotchandpur", "name_ban": "কোটচাঁদপুর"},
                                    {"name_eng": "Moheshpur", "name_ban": "মহেশপুর"}
                                ]
                            }
                        ]
                    },
                    {
                        "name_eng": "Barishal",
                        "name_ban": "বরিশাল",
                        "cities": [
                            {
                                "name_eng": "Jhalakathi",
                                "name_ban": "ঝালকাঠি",
                                "upazilas": [
                                    {"name_eng": "Jhalokati Sadar", "name_ban": "ঝালকাঠি সদর"},
                                    {"name_eng": "Kathalia", "name_ban": "কাঠালিয়া"},
                                    {"name_eng": "Nalchity", "name_ban": "নলছিটি"},
                                    {"name_eng": "Rajapur", "name_ban": "রাজাপুর"}
                                ]
                            },
                            {
                                "name_eng": "Patuakhali",
                                "name_ban": "পটুয়াখালী",
                                "upazilas": [
                                    {"name_eng": "Bauphal", "name_ban": "বাউফল"},
                                    {"name_eng": "Patuakhali", "name_ban": "পটুয়াখালী"},
                                    {"name_eng": "Dumki", "name_ban": "দুমকি"},
                                    {"name_eng": "Dashmina", "name_ban": "দশমিনা"},
                                    {"name_eng": "Kalapara", "name_ban": "কলাপাড়া"},
                                    {"name_eng": "Mirzaganj", "name_ban": "মির্জাগঞ্জ"},
                                    {"name_eng": "Galachipa", "name_ban": "গলাচিপা"},
                                    {"name_eng": "Rangabali", "name_ban": "রাঙ্গাবালী"}
                                ]
                            },
                            {
                                "name_eng": "Pirojpur",
                                "name_ban": "পিরোজপুর",
                                "upazilas": [
                                    {"name_eng": "Pirojpur Sadar", "name_ban": "পিরোজপুর সদর"},
                                    {"name_eng": "Nazirpur", "name_ban": "নাজিরপুর"},
                                    {"name_eng": "Kawkhali", "name_ban": "কাউখালী"},
                                    {"name_eng": "Bhandaria", "name_ban": "ভান্ডারিয়া"},
                                    {"name_eng": "Mathbaria", "name_ban": "মঠবাড়ীয়া"},
                                    {"name_eng": "Nesarabad", "name_ban": "নেছারাবাদ"},
                                    {"name_eng": "Indurkani", "name_ban": "ইন্দুরকানী"}
                                ]
                            },
                            {
                                "name_eng": "Barishal",
                                "name_ban": "বরিশাল",
                                "upazilas": [
                                    
                                    {"name_eng": "Bakerganj", "name_ban": "বাকেরগঞ্জ"},
                                    {"name_eng": "Babuganj", "name_ban": "বাবুগঞ্জ"},
                                    {"name_eng": "Wazirpur", "name_ban": "উজিরপুর"},
                                    {"name_eng": "Banaripara", "name_ban": "বানারীপাড়া"},
                                    {"name_eng": "Gournadi", "name_ban": "গৌরনদী"},
                                    {"name_eng": "Agailjhara", "name_ban": "আগৈলঝাড়া"},
                                    {"name_eng": "Mehendiganj", "name_ban": "মেহেন্দিগঞ্জ"},
                                    {"name_eng": "Muladi", "name_ban": "মুলাদী"},
                                    {"name_eng": "Hizla", "name_ban": "হিজলা"},
                                    {"name_eng": "Kazirhut", "name_ban": "কাজিরহাট"},
                                ]
                            },
                            {
                                "name_eng": "Bhola",
                                "name_ban": "ভোলা",
                                "upazilas": [
                                    {"name_eng": "Bhola", "name_ban": "ভোলা"},
                                    {"name_eng": "Borhanuddin", "name_ban": "বোরহান উদ্দিন"},
                                    {"name_eng": "Charfesson", "name_ban": "চরফ্যাশন"},
                                    {"name_eng": "Doulatkhan", "name_ban": "দৌলতখান"},
                                    {"name_eng": "Monpura", "name_ban": "মনপুরা"},
                                    {"name_eng": "Tazumuddin", "name_ban": "তজুমদ্দিন"},
                                    {"name_eng": "Lalmohan", "name_ban": "লালমোহন"},
                                    {"name_eng": "Shashibhushan", "name_ban": "শশিভুশান"},
                                    {"name_eng": "Dakshin Ayicha ", "name_ban": "দক্ষিন আইচা"},
                                ]
                            },
                            {
                                "name_eng": "Barguna",
                                "name_ban": "বরগুনা",
                                "upazilas": [
                                    {"name_eng": "Amtali", "name_ban": "আমতলী"},
                                    {"name_eng": "Barguna", "name_ban": "বরগুনা"},
                                    {"name_eng": "Betagi", "name_ban": "বেতাগী"},
                                    {"name_eng": "Bamna", "name_ban": "বামনা"},
                                    {"name_eng": "Pathorghata", "name_ban": "পাথরঘাটা"},
                                    {"name_eng": "Taltali", "name_ban": "তালতলি"}
                                ]
                            }
                        ]
                    },
                    {
                        "name_eng": "Sylhet",
                        "name_ban": "সিলেট",
                        "cities": [
                            {
                                "name_eng": "Sylhet",
                                "name_ban": "সিলেট",
                                "upazilas": [
                                    {"name_eng": "Balaganj", "name_ban": "বালাগঞ্জ"},
                                    {"name_eng": "Beanibazar", "name_ban": "বিয়ানীবাজার"},
                                    {"name_eng": "Bishwanath", "name_ban": "বিশ্বনাথ"},
                                    {"name_eng": "Companiganj", "name_ban": "কোম্পানীগঞ্জ"},
                                    {"name_eng": "Fenchuganj", "name_ban": "ফেঞ্চুগঞ্জ"},
                                    {"name_eng": "Golapganj", "name_ban": "গোলাপগঞ্জ"},
                                    {"name_eng": "Gowainghat", "name_ban": "গোয়াইনঘাট"},
                                    {"name_eng": "Jaintiapur", "name_ban": "জৈন্তাপুর"},
                                    {"name_eng": "Kanaighat", "name_ban": "কানাইঘাট"},
                                    {"name_eng": "Zakiganj", "name_ban": "জকিগঞ্জ"},
                                    {"name_eng": "Osmaninagar", "name_ban": "ওসমানীনগর"}
                                ]
                            },
                            {
                                "name_eng": "Moulvibazar",
                                "name_ban": "মৌলভীবাজার",
                                "upazilas": [
                                    {"name_eng": "Barlekha", "name_ban": "বড়লেখা"},
                                    {"name_eng": "Kamolganj", "name_ban": "কমলগঞ্জ"},
                                    {"name_eng": "Kulaura", "name_ban": "কুলাউড়া"},
                                    {"name_eng": "Moulovibazar Model", "name_ban": "মৌলভীবাজার মডেল"},
                                    {"name_eng": "Rajnagar", "name_ban": "রাজনগর"},
                                    {"name_eng": "Sreemangal", "name_ban": "শ্রীমঙ্গল"},
                                    {"name_eng": "Juri", "name_ban": "জুড়ী"}
                                ]
                            },
                            {
                                "name_eng": "Habiganj",
                                "name_ban": "হবিগঞ্জ",
                                "upazilas": [
                                    {"name_eng": "Nabiganj", "name_ban": "নবীগঞ্জ"},
                                    {"name_eng": "Bahubal", "name_ban": "বাহুবল"},
                                    {"name_eng": "Ajmiriganj", "name_ban": "আজমিরীগঞ্জ"},
                                    {"name_eng": "Baniachong", "name_ban": "বানিয়াচং"},
                                    {"name_eng": "Lakhai", "name_ban": "লাখাই"},
                                    {"name_eng": "Chunarughat", "name_ban": "চুনারুঘাট"},
                                    {"name_eng": "Habiganj", "name_ban": "হবিগঞ্জ"},
                                    {"name_eng": "Madhabpur", "name_ban": "মাধবপুর"},
                                    {"name_eng": "Shayestaganj", "name_ban": "শায়েস্তাগঞ্জ"}
                                ]
                            },
                            {
                                "name_eng": "Sunamganj",
                                "name_ban": "সুনামগঞ্জ",
                                "upazilas": [
                                    {"name_eng": "Sunamgonj Sadar", "name_ban": "সুনামগঞ্জ সদর"},
                                    {"name_eng": "South Sunamganj", "name_ban": "দক্ষিণ সুনামগঞ্জ"},
                                    {"name_eng": "Bishwambarpur", "name_ban": "বিশ্বম্ভরপুর"},
                                    {"name_eng": "Chhatak", "name_ban": "ছাতক"},
                                    {"name_eng": "Jagannathpur", "name_ban": "জগন্নাথপুর"},
                                    {"name_eng": "Dowarabazar", "name_ban": "দোয়ারাবাজার"},
                                    {"name_eng": "Tahirpur", "name_ban": "তাহিরপুর"},
                                    {"name_eng": "Dharmapasha", "name_ban": "ধর্মপাশা"},
                                    {"name_eng": "Jamalganj", "name_ban": "জামালগঞ্জ"},
                                    {"name_eng": "Shalla", "name_ban": "শাল্লা"},
                                    {"name_eng": "Derai", "name_ban": "দিরাই"},
                                    {"name_eng": "Madhyanagar", "name_ban": "মধ্যনগর"}
                                ]
                            }
                        ]
                    },
                    {
                        "name_eng": "Dhaka",
                        "name_ban": "ঢাকা",
                        "cities": [
                            {
                                "name_eng": "Narsingdi",
                                "name_ban": "নরসিংদী",
                                "upazilas": [
                                    {"name_eng": "Belabo", "name_ban": "বেলাবো"},
                                    {"name_eng": "Monohardi", "name_ban": "মনোহরদী"},
                                    {"name_eng": "Narshingdi Sadar", "name_ban": "নরসিংদী সদর"},
                                    {"name_eng": "Raipura", "name_ban": "রায়পুরা"},
                                    {"name_eng": "Shibpur", "name_ban": "শিবপুর"},
                                ]
                            },
                            {
                                "name_eng": "Gazipur",
                                "name_ban": "গাজীপুর",
                                "upazilas": [
                                    {"name_eng": "Kaliganj", "name_ban": "কালীগঞ্জ"},
                                    {"name_eng": "Kaliakair", "name_ban": "কালিয়াকৈর"},
                                    {"name_eng": "Kapasia", "name_ban": "কাপাসিয়া"},
                                    {"name_eng": "Tongi", "name_ban": "টঙ্গী"},
                                    {"name_eng": "Sreepur", "name_ban": "শ্রীপুর"},
                                    {"name_eng": "Joydebpur", "name_ban": "জয়দেবপুর"},
                                ]
                            },
                            {
                                "name_eng": "Shariatpur",
                                "name_ban": "শরীয়তপুর",
                                "upazilas": [
                                    {"name_eng": "Naria", "name_ban": "নড়িয়া"},
                                    {"name_eng": "Zajira", "name_ban": "জাজিরা"},
                                    {"name_eng": "Gosairhat", "name_ban": "গোসাইরহাট"},
                                    {"name_eng": "Bhedarganj", "name_ban": "ভেদরগঞ্জ"},
                                    {"name_eng": "Damudya", "name_ban": "ডামুড্যা"},
                                    {"name_eng": "Shakhipur", "name_ban": "শখিপুর"},
                                    {"name_eng": "Palong", "name_ban": "পালং"},
                                ]
                            },
                            {
                                "name_eng": "Narayanganj",
                                "name_ban": "নারায়ণগঞ্জ",
                                "upazilas": [
                                    {"name_eng": "Araihazar", "name_ban": "আড়াইহাজার"},
                                    {"name_eng": "Bandar", "name_ban": "বন্দর"},
                                    {"name_eng": "Narayanganj Sadar", "name_ban": "নারায়নগঞ্জ সদর"},
                                    {"name_eng": "Rupganj", "name_ban": "রূপগঞ্জ"},
                                    {"name_eng": "Sonargaon", "name_ban": "সোনারগাঁ"},
                                    {"name_eng": "Siddhirgonj", "name_ban": "সিদ্ধিরগঞ্জ"},
                                    {"name_eng": "Fotulla", "name_ban": "ফতুল্লা"},
                                ]
                            },
                            {
                                "name_eng": "Tangail",
                                "name_ban": "টাঙ্গাইল",
                                "upazilas": [
                                    {"name_eng": "Basail", "name_ban": "বাসাইল"},
                                    {"name_eng": "Bhuapur", "name_ban": "ভুয়াপুর"},
                                    {"name_eng": "Delduar", "name_ban": "দেলদুয়ার"},
                                    {"name_eng": "Ghatail", "name_ban": "ঘাটাইল"},
                                    {"name_eng": "Gopalpur", "name_ban": "গোপালপুর"},
                                    {"name_eng": "Madhupur", "name_ban": "মধুপুর"},
                                    {"name_eng": "Mirzapur", "name_ban": "মির্জাপুর"},
                                    {"name_eng": "Nagarpur", "name_ban": "নাগরপুর"},
                                    {"name_eng": "Sakhipur", "name_ban": "সখিপুর"},
                                    {"name_eng": "Tangail Sadar", "name_ban": "টাঙ্গাইল সদর"},
                                    {"name_eng": "Kalihati", "name_ban": "কালিহাতী"},
                                    {"name_eng": "Dhanbari", "name_ban": "ধনবাড়ী"},
                                    {"name_eng": "Bangabandhu Bridge East", "name_ban": "বঙ্গবন্ধু সেতু পূর্ব"},
                                ]
                            },
                            {
                                "name_eng": "Kishoreganj",
                                "name_ban": "কিশোরগঞ্জ",
                                "upazilas": [
                                    {"name_eng": "Itna", "name_ban": "ইটনা"},
                                    {"name_eng": "Katiadi Model", "name_ban": "কটিয়াদী মডেল"},
                                    {"name_eng": "Bhairab", "name_ban": "ভৈরব"},
                                    {"name_eng": "Tarail", "name_ban": "তাড়াইল"},
                                    {"name_eng": "Hossainpur", "name_ban": "হোসেনপুর"},
                                    {"name_eng": "Pakundia", "name_ban": "পাকুন্দিয়া"},
                                    {"name_eng": "Kuliarchar", "name_ban": "কুলিয়ারচর"},
                                    {"name_eng": "Kishoregonj Model", "name_ban": "কিশোরগঞ্জ মডেল"},
                                    {"name_eng": "Karimgonj", "name_ban": "করিমগঞ্জ"},
                                    {"name_eng": "Bajitpur", "name_ban": "বাজিতপুর"},
                                    {"name_eng": "Austagram", "name_ban": "অষ্টগ্রাম"},
                                    {"name_eng": "Mithamoin", "name_ban": "মিঠামইন"},
                                    {"name_eng": "Nikli", "name_ban": "নিকলী"}
                                ]
                            },
                            {
                                "name_eng": "Manikganj",
                                "name_ban": "মানিকগঞ্জ",
                                "upazilas": [
                                    {"name_eng": "Harirampur", "name_ban": "হরিরামপুর"},
                                    {"name_eng": "Saturia", "name_ban": "সাটুরিয়া"},
                                    {"name_eng": "Manikganj Sadar", "name_ban": "মানিকগঞ্জ সদর"},
                                    {"name_eng": "Gior", "name_ban": "ঘিওর"},
                                    {"name_eng": "Shibaloy", "name_ban": "শিবালয়"},
                                    {"name_eng": "Doulatpur", "name_ban": "দৌলতপুর"},
                                    {"name_eng": "Singiar", "name_ban": "সিংগাইর"}
                                ]
                            },
                            {
                                "name_eng": "Dhaka",
                                "name_ban": "ঢাকা",
                                "upazilas": [
                                    {"name_eng": "Adabor", "name_ban": "আদাবর"},
                                    {"name_eng": "Badda", "name_ban": "বাড্ডা"},
                                    {"name_eng": "Banani", "name_ban": "বনানী"},
                                    {"name_eng": "Bangshal", "name_ban": "বংশাল"},
                                    {"name_eng": "Bimanbondor", "name_ban": "বিমানবন্দর"},
                                    {"name_eng": "Cantonment", "name_ban": "ক্যান্টনমেন্ট"},
                                    {"name_eng": "Chalkbazar", "name_ban": "চকবাজার"},
                                    {"name_eng": "Dakshinkhan", "name_ban": "দক্ষিনখান"},
                                    {"name_eng": "Darus-Salam", "name_ban": "দারুস সালাম"},
                                    {"name_eng": "Demra", "name_ban": "ডেমরা"},
                                    {"name_eng": "Dhanmondi", "name_ban": "ধানমন্ডি"},
                                    {"name_eng": "Gandaria", "name_ban": "গান্দারিয়া"},
                                    {"name_eng": "Gulshan", "name_ban": "গুলশান"},
                                    {"name_eng": "Hazaribag", "name_ban": "হাজারিবাগ"},
                                    {"name_eng": "Jatrabari", "name_ban": "যাত্রাবারি"},
                                    {"name_eng": "Kafrul", "name_ban": "কাফরুল"},
                                    {"name_eng": "Kalabagan", "name_ban": "কলাবাগান"},
                                    {"name_eng": "Kamrangirchar", "name_ban": "কামরাঙ্গিচর"},
                                    {"name_eng": "Khilgaon", "name_ban": "খিলগাঁও"},
                                    {"name_eng": "Khilkhet", "name_ban": "খিলখেত"},
                                    {"name_eng": "Kadamtoli", "name_ban": "কদমতলি"},
                                    {"name_eng": "Kotwali", "name_ban": "কোতওয়ালি"},
                                    {"name_eng": "Lalbagh", "name_ban": "লালবাগ"},
                                    {"name_eng": "Mirpur Model", "name_ban": "মিরপুর মডেল"},
                                    {"name_eng": "Mirpur", "name_ban": "মিরপুর"},
                                    {"name_eng": "Mohammadpur", "name_ban": "মোহাম্মদপুর"},
                                    {"name_eng": "Motijheel", "name_ban": "মতিঝিল"},
                                    {"name_eng": "Mugda", "name_ban": "মুগদা"},
                                    {"name_eng": "New Market", "name_ban": "নিউ মার্কেট"},
                                    {"name_eng": "Pallabi", "name_ban": "পল্লবী"},
                                    {"name_eng": "Paltan", "name_ban": "পল্টন"},
                                    {"name_eng": "Ramna", "name_ban": "রমনা"},
                                    {"name_eng": "Rampura", "name_ban": "রামপুরা"},
                                    {"name_eng": "Rupnagar", "name_ban": "রূপনগর"},
                                    {"name_eng": "Sabujbag", "name_ban": "সবুজবাগ"},
                                    {"name_eng": "Shah Ali", "name_ban": "শাহ্‌ আলি"},
                                    {"name_eng": "Shahbagh", "name_ban": "শাহ্‌বাগ"},
                                    {"name_eng": "Shahjahanpur", "name_ban": "শাহজাহানপুর"},
                                    {"name_eng": "Shyampur", "name_ban": "শ্যামপুর"},
                                    {"name_eng": "Tejgaon", "name_ban": "তেজগাঁও"},
                                    {"name_eng": "Sher-E-Bangla", "name_ban": "শের-ই-বাংলা"},
                                    {"name_eng": "Tejgaon Shilpanchal ", "name_ban": "তেজগাঁও শিল্পাঞ্চল"},
                                    {"name_eng": "Turag ", "name_ban": "তুরাগ"},
                                    {"name_eng": "Uttara East", "name_ban": "উত্তরা পূর্ব"},
                                    {"name_eng": "Uttara West", "name_ban": "উত্তরা পশ্চিম"},
                                    {"name_eng": "Uttarkhan", "name_ban": "উত্তরখান"},
                                    {"name_eng": "Vashantek", "name_ban": "ভাশান্টেক"},
                                    {"name_eng": "Vatara", "name_ban": "ভাটারা"},
                                    {"name_eng": "Wari", "name_ban": "ওয়ারি"},
                                    
                                ]
                            },
                            {
                                "name_eng": "Munshiganj",
                                "name_ban": "মুন্সিগঞ্জ",
                                "upazilas": [
                                    {"name_eng": "Munshigonj Sadar", "name_ban": "মুন্সিগঞ্জ সদর"},
                                    {"name_eng": "Sreenagar", "name_ban": "শ্রীনগর"},
                                    {"name_eng": "Sirajdikhan", "name_ban": "সিরাজদিখান"},
                                    {"name_eng": "Louhajanj", "name_ban": "লৌহজং"},
                                    {"name_eng": "Gajaria", "name_ban": "গজারিয়া"},
                                    {"name_eng": "Tongibari", "name_ban": "টংগীবাড়ি"}
                                ]
                            },
                            {
                                "name_eng": "Rajbari",
                                "name_ban": "রাজবাড়ী",
                                "upazilas": [
                                    {"name_eng": "Rajbari Sadar", "name_ban": "রাজবাড়ী সদর"},
                                    {"name_eng": "Goalanda", "name_ban": "গোয়ালন্দ"},
                                    {"name_eng": "Pangsa", "name_ban": "পাংশা"},
                                    {"name_eng": "Baliakandi", "name_ban": "বালিয়াকান্দি"},
                                    {"name_eng": "Kalukhali", "name_ban": "কালুখালী"}
                                ]
                            },
                            {
                                "name_eng": "Madaripur",
                                "name_ban": "মাদারীপুর",
                                "upazilas": [
                                    {"name_eng": "Madaripur Sadar", "name_ban": "মাদারীপুর সদর"},
                                    {"name_eng": "Shibchar", "name_ban": "শিবচর"},
                                    {"name_eng": "Kalkini", "name_ban": "কালকিনি"},
                                    {"name_eng": "Rajoir", "name_ban": "রাজৈর"},
                                    {"name_eng": "Chashar", "name_ban": "চাশার"}
                                ]
                            },
                            {
                                "name_eng": "Gopalganj",
                                "name_ban": "গোপালগঞ্জ",
                                "upazilas": [
                                    {"name_eng": "Gopalgonj Sadar", "name_ban": "গোপালগঞ্জ সদর"},
                                    {"name_eng": "Kashiani", "name_ban": "কাশিয়ানী"},
                                    {"name_eng": "Tungipara", "name_ban": "টুংগীপাড়া"},
                                    {"name_eng": "Kotalipara", "name_ban": "কোটালীপাড়া"},
                                    {"name_eng": "Muksudpur", "name_ban": "মুকসুদপুর"}
                                ]
                            },
                            {
                                "name_eng": "Faridpur",
                                "name_ban": "ফরিদপুর",
                                "upazilas": [
                                    {"name_eng": "Alfadanga", "name_ban": "আলফাডাঙ্গা"},
                                    {"name_eng": "Boalmari", "name_ban": "বোয়ালমারী"},
                                    {"name_eng": "Sadarpur", "name_ban": "সদরপুর"},
                                    {"name_eng": "Nagarkanda", "name_ban": "নগরকান্দা"},
                                    {"name_eng": "Bhanga", "name_ban": "ভাঙ্গা"},
                                    {"name_eng": "Charbhadrasan", "name_ban": "চরভদ্রাসন"},
                                    {"name_eng": "Madhukhali", "name_ban": "মধুখালী"},
                                    {"name_eng": "Saltha", "name_ban": "সালথা"},
                                    {"name_eng": "Kotwali", "name_ban": "কোতওয়ালি"}
                                ]
                            }
                        ]
                    },
                    {
                        "name_eng": "Rangpur",
                        "name_ban": "রংপুর",
                        "cities": [
                            {
                                "name_eng": "Panchagarh",
                                "name_ban": "পঞ্চগড়",
                                "upazilas": [
                                    { "name_eng": "Panchagor Sadar", "name_ban": "পঞ্চগড় সদর" },
                                    { "name_eng": "Boda", "name_ban": "বোদা" },
                                    { "name_eng": "Atowari", "name_ban": "আটয়ারি" },
                                    { "name_eng": "Tetuliya", "name_ban": "তেতুলিয়া" },
                                    { "name_eng": "Debiganj", "name_ban": "দেবীগঞ্জ" },
                                ]
                            },
                            {
                                "name_eng": "Dinajpur",
                                "name_ban": "দিনাজপুর",
                                "upazilas": [
                                    { "name_eng": "Nawabganj", "name_ban": "নবাবগঞ্জ" },
                                    { "name_eng": "Birganj", "name_ban": "বীরগঞ্জ" },
                                    { "name_eng": "Ghoraghat", "name_ban": "ঘোড়াঘাট" },
                                    { "name_eng": "Birampur", "name_ban": "বিরামপুর" },
                                    { "name_eng": "Parbatipur", "name_ban": "পার্বতীপুর" },
                                    { "name_eng": "Bochaganj", "name_ban": "বোচাগঞ্জ" },
                                    { "name_eng": "Kaharol", "name_ban": "কাহারোল" },
                                    { "name_eng": "Fulbari", "name_ban": "ফুলবাড়ী" },
                                    { "name_eng": "Kotowali", "name_ban": "কোতওয়ালি" },
                                    { "name_eng": "Hakimpur", "name_ban": "হাকিমপুর" },
                                    { "name_eng": "Khansama", "name_ban": "খানসামা" },
                                    { "name_eng": "Birol", "name_ban": "বিরল" },
                                    { "name_eng": "Chirirbandar", "name_ban": "চিরিরবন্দর" }
                                ]
                            },
                            {
                                "name_eng": "Lalmonirhat",
                                "name_ban": "লালমনিরহাট",
                                "upazilas": [
                                    { "name_eng": "Lalmonirhat", "name_ban": "লালমনিরহাট" },
                                    { "name_eng": "Kaliganj", "name_ban": "কালীগঞ্জ" },
                                    { "name_eng": "Hatibandha", "name_ban": "হাতীবান্ধা" },
                                    { "name_eng": "Patgram", "name_ban": "পাটগ্রাম" },
                                    { "name_eng": "Aditmari", "name_ban": "আদিতমারী" }
                                ]
                            },
                            {
                                "name_eng": "Nilphamari",
                                "name_ban": "নীলফামারী",
                                "upazilas": [
                                    { "name_eng": "Syedpur", "name_ban": "সৈয়দপুর" },
                                    { "name_eng": "Domar", "name_ban": "ডোমার" },
                                    { "name_eng": "Dimla", "name_ban": "ডিমলা" },
                                    { "name_eng": "Jaldhaka", "name_ban": "জলঢাকা" },
                                    { "name_eng": "Kishorganj", "name_ban": "কিশোরগঞ্জ" },
                                    { "name_eng": "Nilphamari", "name_ban": "নীলফামারী" }
                                ]
                            },
                            {
                                "name_eng": "Gaibandha",
                                "name_ban": "গাইবান্ধা",
                                "upazilas": [
                                    { "name_eng": "Sadullapur", "name_ban": "সাদুল্লাপুর" },
                                    { "name_eng": "Gaibandha Sadar", "name_ban": "গাইবান্ধা সদর" },
                                    { "name_eng": "Palashbari", "name_ban": "পলাশবাড়ী" },
                                    { "name_eng": "Saghata", "name_ban": "সাঘাটা" },
                                    { "name_eng": "Gobindaganj", "name_ban": "গোবিন্দগঞ্জ" },
                                    { "name_eng": "Sundarganj", "name_ban": "সুন্দরগঞ্জ" },
                                    { "name_eng": "Phulchari", "name_ban": "ফুলছড়ি" }
                                ]
                            },
                            {
                                "name_eng": "Thakurgaon",
                                "name_ban": "ঠাকুরগাঁও",
                                "upazilas": [
                                    { "name_eng": "Thakurgaon", "name_ban": "ঠাকুরগাঁ" },
                                    { "name_eng": "Baliadangi", "name_ban": "বালিয়াডাঙ্গি" },
                                    { "name_eng": "Ranishonkoil", "name_ban": "রানিসংকইল" },
                                    { "name_eng": "Pirganj", "name_ban": "পিরানগঞ্জ" },
                                    { "name_eng": "Horipur", "name_ban": "হরিপুর" },
                                    { "name_eng": "Ruhia", "name_ban": "রুহিয়া" },
                                ]
                            },
                            {
                                "name_eng": "Rangpur",
                                "name_ban": "রংপুর",
                                "upazilas": [
                                    { "name_eng": "Kotwali", "name_ban": "কোতওয়ালি" },
                                    { "name_eng": "Gangachara", "name_ban": "গংগাচড়া" },
                                    { "name_eng": "Taragonj", "name_ban": "তারাগঞ্জ" },
                                    { "name_eng": "Badargonj", "name_ban": "বদরগঞ্জ" },
                                    { "name_eng": "Mithapukur", "name_ban": "মিঠাপুকুর" },
                                    { "name_eng": "Pirojpur", "name_ban": "পিরোজপুর" },
                                    { "name_eng": "Kaunia", "name_ban": "কাউনিয়া" },
                                    { "name_eng": "Pirgacha", "name_ban": "পীরগাছা" }
                                ]
                            },
                            {
                                "name_eng": "Kurigram",
                                "name_ban": "কুড়িগ্রাম",
                                "upazilas": [
                                    { "name_eng": "Kurigram Sadar", "name_ban": "কুড়িগ্রাম সদর" },
                                    { "name_eng": "Nageshwari", "name_ban": "নাগেশ্বরী" },
                                    { "name_eng": "Bhurungamari", "name_ban": "ভুরুঙ্গামারী" },
                                    { "name_eng": "Phulbari", "name_ban": "ফুলবাড়ী" },
                                    { "name_eng": "Bajarhat", "name_ban": "বাজারহাট" },
                                    { "name_eng": "Ulipur", "name_ban": "উলিপুর" },
                                    { "name_eng": "Chilmari", "name_ban": "চিলমারী" },
                                    { "name_eng": "Rowmari", "name_ban": "রৌমারী" },
                                    { "name_eng": "Rajibpur", "name_ban": "রাজিবপুর" },
                                    { "name_eng": "Dushmara", "name_ban": "দুশমারা" },
                                    { "name_eng": "Kochakata", "name_ban": "কচাকাটা" },
                                ]
                            }
                        ]
                    },
                    {
                        "name_eng": "Mymensingh",
                        "name_ban": "ময়মনসিংহ",
                        "cities": [
                            {
                                "name_eng": "Sherpur",
                                "name_ban": "শেরপুর",
                                "upazilas": [
                                    { "name_eng": "Sherpur Sadar", "name_ban": "শেরপুর সদর" },
                                    { "name_eng": "Nalitabari", "name_ban": "নালিতাবাড়ী" },
                                    { "name_eng": "Sreebordi", "name_ban": "শ্রীবরদী" },
                                    { "name_eng": "Nokla", "name_ban": "নকলা" },
                                    { "name_eng": "Jhenaigati", "name_ban": "ঝিনাইগাতী" }
                                ]
                            },
                            {
                                "name_eng": "Mymensingh",
                                "name_ban": "ময়মনসিংহ",
                                "upazilas": [
                                    { "name_eng": "Fulbaria", "name_ban": "ফুলবাড়ীয়া" },
                                    { "name_eng": "Trishal", "name_ban": "ত্রিশাল" },
                                    { "name_eng": "Bhaluka", "name_ban": "ভালুকা" },
                                    { "name_eng": "Muktagacha", "name_ban": "মুক্তাগাছা" },
                                    { "name_eng": "Kotwali", "name_ban": "কোতওয়ালি" },
                                    { "name_eng": "Dhobaura", "name_ban": "ধোবাউড়া" },
                                    { "name_eng": "Phulpur", "name_ban": "ফুলপুর" },
                                    { "name_eng": "Haluaghat", "name_ban": "হালুয়াঘাট" },
                                    { "name_eng": "Gouripur", "name_ban": "গৌরীপুর" },
                                    { "name_eng": "Gafargaon", "name_ban": "গফরগাঁও" },
                                    { "name_eng": "Iswarganj", "name_ban": "ঈশ্বরগঞ্জ" },
                                    { "name_eng": "Nandail", "name_ban": "নান্দাইল" },
                                    { "name_eng": "Tarakanda", "name_ban": "তারাকান্দা" },
                                    { "name_eng": "Pagla", "name_ban": "পাগলা" },
                                ]
                            },
                            {
                                "name_eng": "Jamalpur",
                                "name_ban": "জামালপুর",
                                "upazilas": [
                                    { "name_eng": "Jamalpur", "name_ban": "জামালপুর" },
                                    { "name_eng": "Melandah", "name_ban": "মেলান্দহ" },
                                    { "name_eng": "Islampur", "name_ban": "ইসলামপুর" },
                                    { "name_eng": "Dewangonj", "name_ban": "দেওয়ানগঞ্জ" },
                                    { "name_eng": "Sarishabari", "name_ban": "সরিষাবাড়ী" },
                                    { "name_eng": "Madarganj", "name_ban": "মাদারগঞ্জ" },
                                    { "name_eng": "Bokshiganj", "name_ban": "বকশীগঞ্জ" },
                                    { "name_eng": "Bahadurabad", "name_ban": "বাহাদুরাবাদ" }
                                ]
                            },
                            {
                                "name_eng": "Netrokona",
                                "name_ban": "নেত্রকোণা",
                                "upazilas": [
                                    { "name_eng": "Barhatta", "name_ban": "বারহাট্টা" },
                                    { "name_eng": "Durgapur", "name_ban": "দুর্গাপুর" },
                                    { "name_eng": "Kendua", "name_ban": "কেন্দুয়া" },
                                    { "name_eng": "Atpara", "name_ban": "আটপাড়া" },
                                    { "name_eng": "Madan", "name_ban": "মদন" },
                                    { "name_eng": "Khaliajuri", "name_ban": "খালিয়াজুরী" },
                                    { "name_eng": "Kalmakanda", "name_ban": "কলমাকান্দা" },
                                    { "name_eng": "Mohongonj", "name_ban": "মোহনগঞ্জ" },
                                    { "name_eng": "Purbadhala", "name_ban": "পূর্বধলা" },
                                    { "name_eng": "Netrokona Model", "name_ban": "নেত্রকোণা মডেল" }
                                ]
                            }
                        ]
                    }
                ]
            }
        ]

        for con in data:
            print('contry: %s' % con['name_eng'])
            con_obj = Country.objects.create(name_eng=con['name_eng'], name_ban=con['name_ban'])
            for reg in con['regions']:
                print('region: %s' % reg['name_eng'])
                reg_obj = Region.objects.create(name_eng=reg['name_eng'], name_ban=reg['name_ban'], country=con_obj)
                for cit in reg['cities']:
                    print('city: %s' % cit['name_eng'])
                    cit_obj = City.objects.create(name_eng=cit['name_eng'], name_ban=cit['name_ban'], region=reg_obj)
                    for upa in cit['upazilas']:
                        print('upazila: %s' % upa['name_eng'])
                        Upazila.objects.create(name_eng=upa['name_eng'], name_ban=upa['name_ban'], city=cit_obj)
        print("Data Loaded")