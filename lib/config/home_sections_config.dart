import 'package:alkirtas/models/home_section.dart';
import 'package:iconsax/iconsax.dart';

final List<HomeSection> homeSections = [
  HomeSection(
    icon: Iconsax.book_1,
    title: "Sélection de Livres",
    
    tabs: [
      CategoryTab(name: "Français", categoryId: 14),
      CategoryTab(name: "English", categoryId: 15),
      CategoryTab(name: "عربي", categoryId: 13),
    ],
  ),
  HomeSection(
    icon: Iconsax.teacher,
    title: "Scolarité & Spécial Rentrée",
    
    tabs: [
      CategoryTab(name: "Parascolaires", categoryId: 17),
      CategoryTab(name: "Bagagerie", categoryId: 12),
      CategoryTab(name: "Ecriture & Correction", categoryId: 122),
      CategoryTab(name: "Papetrie", categoryId: 120),
     
    ],
  ),
  HomeSection(
    icon: Iconsax.monitor_mobbile,
    title: "Espace Bureaux",
    
    tabs: [
      CategoryTab(name: "Accessoires  Bureau ", categoryId: 558),
      CategoryTab(name: "High-Tech" , categoryId: 569),
      CategoryTab(name: "Agendas & Calendriers " , categoryId: 121),
      CategoryTab(name: "Ecriture & Correction", categoryId: 122),
      
      
      
    ],
  ),
  HomeSection(
    icon: Iconsax.game,
    title: "Jeux & Créativité",
    
    tabs: [
      CategoryTab(name: "Jeux et Jouets", categoryId: 590),
      CategoryTab(name: "Art & Loisirs ", categoryId: 743),
      
    ],
  ),
  HomeSection(
    icon: Iconsax.gift,
    title: "Cadeaux & Fêtes",
    
    tabs: [
      CategoryTab(name: "Décorations de fêtes" , categoryId:  587),
      CategoryTab(name: "Idées Cadeaux ", categoryId:  838 ),
      
      CategoryTab(name: "Accessoires de Beauté" , categoryId: 877),
    ],
  ),
];