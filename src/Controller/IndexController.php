<?php

namespace App\Controller;

use App\Repository\OfferRepository;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class IndexController extends AbstractController
{
    #[Route('/', name: 'app_index')]
    public function index(OfferRepository $offerRepository): Response
    {
        return $this->render('index/index.html.twig', [
            'controller_name' => 'IndexController',
            'offers' => $offerRepository->findBy([], ['id' => 'DESC'], 3)
        ]);
    }

    #[Route('/mentions-légales', name: 'app_index_mention')]
    public function mention(): Response
    {
        return $this->render('index/mention.html.twig', [
            'controller_name' => 'IndexController',
        ]);
    }
}
