import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditions d\'utilisation',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.purple[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Conditions d'utilisation",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                "Bienvenue sur Alkirtas! Voici les termes et conditions d'utilisation de notre plateforme. "
                "En utilisant notre application, vous acceptez les règles suivantes :",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                "ARTICLE 1 - PRIX",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                "1.1 - Les prix de nos produits sont indiqués en Dinars toutes taxes (TVA et autres taxes) comprises hors participation aux frais de port et sont valables tant qu´ils sont présents à l´écran.\n1.2 - Toutes les commandes sont payables en Dinars Tunisiens.\n1.3 - ALKIRTAS se réserve le droit de modifier ses prix à tout moment mais les produits seront facturés au tarif en vigueur au moment de la création de commande.\n1.4 - Les produits demeurent la propriété de ALKIRTAS jusqu´au complet encaissement du prix.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                "ARTICLE 2 - COMMANDE",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                "Les commandes sont à passer sur le site Internet : www.alkirtas.com ou par téléphone au 72 413 913 ou par l'application mobile Alkirtas ou à notre siège à BIZERTE.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                "ARTICLE 3 - VALIDATION",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              
              Text(
                "1 - Quand vous cliquez sur le bouton \"Confirmer la commande\" après le processus de commande, vous déclarez avoir pris connaissance et accepter les présentes Conditions Générales de Vente pleinement et sans réserve.\n 2 - En l´absence de réception de ces pièces dans un délai de 30 jours à compter de la date d´expédition de la demande, la commande sera réputée annulée de plein droit. Sauf preuves contraires, les données enregistrées par ALKIRTAS constituent la preuve de l´ensemble des transactions passées entre ALKIRTAS et ses clients.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                "ARTICLE 4 - DISPONIBILITÉ",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              
              Text(
                "Nos offres de produits sont valables tant qu´elles sont visibles à l´écran, dans la limite des stocks disponibles hors opérations promotionnelles mentionnées comme telles sur les sites.En cas d´indisponibilité de produit après passation de votre commande nous vous en informerons par mail dans les meilleurs délais et vous pourrez alors modifier ou annuler votre commande dans un délai de 60 jours ouvrés et nous procèderont au remboursement du produit et des frais d´envoi en cas d´encaissement du prix.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
               Text(
                "ARTICLE 5 - PAIEMENT",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              
              Text(
                "Le règlement de vos achats peut s´effectuer par espèces lors de la livraison,",
                                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
               Text(
                "ARTICLE 6 - LIVRAISON",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              
              Text(
                "I - Généralités\n\nLes produits achetés sur l'application Alkirtas peuvent faire l´objet d´une livraison par transporteur\nLe Client choisit son mode de livraison lors de la passation en ligne de sa commande . Ce choix est irrévocable une fois la validation de la commande effectuée.\nLivraison à domicil\nDans le cas où le client souhaite que sa commande soit livrée à domicile, les produits achetés sur Alkirtas ne sont livrés qu´en Tunisie. Les produits sont livrés au lieu de livraison dans l'étape Livraison lors du passage de commande soit avant la validation de la commande.\nRetards d´expédition, de livraison et mise à dispositio\nEn cas de retard d´expédition, un mail vous sera adressé pour vous informer d'une éventuelle conséquence sur la date limite de livraison\nNous vous invitons également à consulter régulièrement votre suivi de commande et à contacter le Service Client pour toute question.\n\nII - Problèmes de livraison – qualité et conformité des produits\nVous devez vérifier la conformité de la marchandise livrée au moment de la livraison avant de signer le bon de livraison ou le reçu de la Poste et indiquer toute anomalie concernant la livraison (erreur, produit endommagé, déjà ouvert notamment). Dans le cas d´anomalie, ALKIRTAS s´engage à vous rembourser ou à vous échanger les produits ne correspondant pas à votre commande (défectueux ou non conformes) après que vous ayez fait part de votre réclamation en précisant vos coordonnées, votre numéro de facture, les références du produit figurant sur la facture, par mail au Service Client ([email protected]) ou par courrier.\n\nIII - Colis non reçus (livraison par transporteur)\nVous disposez d´un délai de 60 jours après la date d´expédition de votre commande pour nous signaler tout problème de réception de votre colis. Au-delà de ce délai, toute réclamation sera considérée comme non recevable. En cas de retard de la livraison par la poste dans un délai de huit jours ouvrés suivant la date d´expédition indiquée dans le courriel « suivi avis d´expédition », ALKIRTAS suggère au client de vérifier auprès de son bureau de poste si le colis n'est pas en instance, puis le cas échéant, l´invite à signaler ce retard en contactant le service clients en priorité par téléphone ou en adressant un courriel. ALKIRTAS contactera alors la Poste afin de démarrer une enquête. Sans préjudice des autres droits du client, ALKIRTAS n´enverra de produit de remplacement à ses frais qu´à la clôture de cette enquête. Si le ou les produits commandés venaient à ne plus être disponibles, ALKIRTAS remboursera les produits concernés.",
                                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
                  Text(
                "ARTICLE 7 - ACCOMPAGNEMENT PAR NOS ÉQUIPES",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              
              Text(
                "Vous souhaitez vous renseigner ou commander un produit sur notre site ou notre application mobile ? Appelez notre Service Commercial tous les jours de la semaine de 9h à 19h au 72 413 913.",
                                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
               const SizedBox(height: 16),
                  Text(
                "ARTICLE 8 - RESPONSABILITÉ",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              
              Text(
                "Les produits proposés sont conformes à la législation Tunisienne en vigueur et aux normes applicables en Tunisie. Les photographies, graphismes, reproduits sont communiqués à titre indicatifs. Bien entendu pour toute question sur les produits vous pouvez contacter notre service clientèle par tél: 72 413 913.\nALKIRTAS ne saurait être tenu pour responsable de force majeure, de perturbation ou grève totale ou partielle notamment des services postaux et moyens de transport et/ou communications, inondation, incendie ou en cas d´erreur manifeste. ALKIRTAS n´encourra aucune responsabilité pour tout dommage immatériel et indirect du fait des présentes à savoir : perte d´exploitation, perte de profit, perte de chance, qui pourraient survenir du fait de l´achat des produits.\nous vous rappelons qu´il est prudent de procéder à la sauvegarde des données contenues dans les produits achetés. ALKIRTAS ne saurait être responsable de toutes pertes de données, fichiers ou des dommages définis au paragraphe précédent. L´impossibilité totale ou partielle d´utiliser les produits notamment pour cause d´incompatibilité de matériels ne peut donner lieu à aucun dédommagement ou remboursement ou mise en cause de la responsabilité de ALKIRTAS. ",
                                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                "Pour plus d'informations, veuillez consulter notre site web officiel.",
                style: Theme.of(context).textTheme.bodyMedium,
                
              ),
              const SizedBox(height: 16),
                  Text(
                "ARTICLE 9 - GARANTIE",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              
              Text(
                "Les produits achetés chez ALKIRTAS donnent droit à la garantie dont la durée est indiquée sur la fiche article des produits présentés sur le site. En tout état de cause, vous bénéficiez des garanties légales de conformité et des vices cachés, et ce conformément aux dispositions légales en vigueur, pour une durée minimale d’une année. Pour pouvoir bénéficier de la garantie des produits il convient impérativement de nous adresser la facture d´achat avec votre produit.\nLes garanties contractuelles ne couvrent pas:\n- Le remplacement des consommables (batteries, ampoules, fusibles, antennes, casques de baladeurs, microphones, usure de têtes d´enregistrement ou de lecture…)\n- L´utilisation anormale ou non conforme des produits. Nous vous invitons à cet égard à consulter attentivement la notice d´emploi fournie avec les produits\n- Les pannes liées aux accessoires (câbles d´alimentation)\n- Les défauts et leurs conséquences dus à l´intervention d´un réparateur non agréé par ALKIRTAS\n- Les défauts et leurs conséquences liés à l´utilisation non conforme à l´usage pour lequel le produit est destiné (utilisation professionnelle, collective...)\n- Les défauts et leurs conséquences liés à toute cause extérieure\nTout matériel cassé, brûlé ou endommagé n´est pas couvert par la garantie constructeur.",
                                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                "ARTICLE 10 - MENTIONS LÉGALES",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              
              Text(
                "L'applicatin mobile Alkirtas est une publication de :\nALKIRTAS SARL,\nComplexe BIZERTE CENTRE N°30 7000\nBizerte Tunisie\nLes marques citées appartiennent à leurs propriétaires respectifs.",
                                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                "Pour plus d'informations, veuillez consulter notre site web officiel www.alkirtas.com ou nous contacter au 72 413 913.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
