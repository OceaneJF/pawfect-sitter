<?php

namespace App\Controller;

use App\Entity\Offer;
use App\Form\OfferType;
use App\Repository\OfferRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\File\Exception\FileException;
use Symfony\Component\HttpFoundation\File\UploadedFile;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\RequestStack;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;

class OfferController extends AbstractController
{
    #[Route('/offers', name: 'app_offers')]
    public function index(OfferRepository $offerRepository): Response
    {
        return $this->render('offer/offers.html.twig', [
            'controller_name' => 'OfferController',
            'offers' => array_reverse($offerRepository->findAll()),
        ]);
    }

    #[Route('/my-offer', name: 'app_offer')]
    #[IsGranted('ROLE_USER')]
    public function offersByUser(OfferRepository $offerRepository, RequestStack $requestStack): Response
    {
        $user = $this->getUser();
        $request = $requestStack->getCurrentRequest();
        $baseUrl = $request->getSchemeAndHttpHost();

        $offersToArray = array_map(function ($offer) use ($baseUrl) {
            return [
                'id' => $offer->getId(),
                'name' => $offer->getName(),
                'age' => $offer->getAge(),
                'address' => $offer->getAddress(),
                'nameOwner' => $offer->getNameOwner(),
                'pricing' => $offer->getPricing(),
                'type' => $offer->getType(),
                'duration' => $offer->getDuration(),
                'user' => $offer->getUser()->getId(),
                'startDate' => $offer->getStartDate(),
                'img' => $offer->getImageName() ? $baseUrl . '/img/animals/' . $offer->getImageName() : "https://ralfvanveen.com/wp-content/uploads/2021/06/Espace-r%C3%A9serv%C3%A9-_-Glossaire.svg",
            ];
        }, $offerRepository->findBy(['user' => $user]));

        return $this->render('offer/my_offer.html.twig', [
            'controller_name' => 'OfferController',
            'offers' => $offersToArray,
        ]);
    }

    #[Route('/offer/add', name: 'app_offer_add')]
    #[IsGranted('ROLE_USER')]
    public function addOfferToUser(Request $request, EntityManagerInterface $em): JsonResponse
    {
        $user = $this->getUser();
        $offer = new Offer();
        $form = $this->createForm(OfferType::class, $offer);
        $form->handleRequest($request);

        if (!$form->isSubmitted() || !$form->isValid()) {
            $errors = [];
            foreach ($form->getErrors(true) as $error) {
                $errors[$error->getOrigin()->getName()] = $error->getMessage();
            }

            return new JsonResponse($errors, 400);
        }

        /** @var UploadedFile $file */
        $file = $form->get('imageFile')->getData();

        if ($file) {
            $newFilename = uniqid() . '.' . $file->guessExtension();

            try {
                $file->move(
                    "img/animals",
                    $newFilename
                );
            } catch (FileException $e) {
                return $this->json(['error' => 'File upload failed'], 500);
            }
            $offer->setImageName($newFilename);
        }

        $offer->setUser($user);
        $user->addOffer($offer);

        $em->persist($user);
        $em->persist($offer);
        $em->flush();

        return $this->json([], 200);
    }

    #[Route('/offer/update/{id}', name: 'app_offer_update')]
    #[IsGranted('ROLE_USER')]
    public function updateOfferToUser(int $id, Request $request, OfferRepository $offerRepository, EntityManagerInterface $em): JsonResponse
    {
        $user = $this->getUser();
        $offer = $offerRepository->find($id);
        $form = $this->createForm(OfferType::class, $offer);
        $form->handleRequest($request);

        if (!$form->isSubmitted() || !$form->isValid()) {
            $errors = [];
            foreach ($form->getErrors(true) as $error) {
                $errors[$error->getOrigin()->getName()] = $error->getMessage();
            }

            return new JsonResponse($errors, 400);
        }

        /** @var UploadedFile $file */
        $file = $form->get('imageFile')->getData();

        if ($file) {
            $newFilename = uniqid() . '.' . $file->guessExtension();

            try {
                $file->move(
                    "img/animals",
                    $newFilename
                );
            } catch (FileException $e) {
                return $this->json(['error' => 'File upload failed'], 500);
            }
            $offer->setImageName($newFilename);
        }

        $offer->setUser($user);
        $user->addOffer($offer);

        $em->persist($user);
        $em->persist($offer);
        $em->flush();

        return $this->json([], 200);
    }

    #[Route('/offer/detete/{id}', name: 'app_offer_delete')]
    #[IsGranted('ROLE_USER')]
    public function removeOfferToUser(int $id, OfferRepository $offerRepository, EntityManagerInterface $em): JsonResponse
    {
        $user = $this->getUser();
        $offre = $offerRepository->find($id);

        if ($offre->getUser() === $user) {
            $em->remove($offre);
            $em->flush();
        }

        return $this->json([], 200);
    }

    #[Route('/offer/{id}', name: 'app_offer_id', methods: ['GET'])]
    public function offerById(int $id, OfferRepository $offerRepository): Response
    {
        return $this->render('offer/offer_detail.html.twig', [
            'controller_name' => 'OfferController',
            'offer' => $offerRepository->find($id),
        ]);
    }
}
