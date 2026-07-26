import asyncio, logging, requests, os
from urllib.parse import urljoin
from pathlib import Path
from playwright.async_api import async_playwright, Playwright, Locator, Page, Browser
import requests
from tqdm.asyncio import tqdm
import argparse

argparse = argparse.ArgumentParser()

argparse.add_argument("artist", choices=["klimt"], help="which artist to download")

args = argparse.parse_args()


logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")


url_map = {"klimt": "http://art-klimt.com/gallery.html"}
semaphore = asyncio.Semaphore(5)

successfully_downloaded = 0
errors = []

def save_image(target_dir: Path, image_url: str):
    path = Path(image_url)
    target = target_dir.joinpath(path.name)
    if not os.path.exists(target):
        # logging.info(f"downloading: {image_url} to {target}")
        response = requests.get(image_url)
        response.raise_for_status()

        # 3. Save it to a file
        with open(target, "wb") as f:
            f.write(response.content)


async def visit_subpage_and_download_artwork(browser: Browser, target_dir: Path, image_page_url: str):
    # logging.info(f"visiting: {image_page_url}")
    global successfully_downloaded
    async with semaphore:
        try:
            context = await browser.new_context()
            page = await context.new_page()
            await page.goto(image_page_url)
            image = page.locator("figure > a").first
            image_href = await image.get_attribute("href")
            image_url = urljoin(page.url, image_href)

            await asyncio.to_thread(save_image, target_dir, image_url)
            successfully_downloaded += 1
        except Exception as e:
            logger.info(f"Error while visiting {image_page_url}: {e}")
            errors.append((image_page_url, e))

async def download_artist(playwright: Playwright, target_dir: Path, url: str):
    logger.info("starting browser...")
    chromium = playwright.chromium  # or "firefox" or "webkit".
    browser = await chromium.launch()
    page = await browser.new_page()

    logger.info(f"visiting url: {url}")
    await page.goto(url)

    logger.info("fetching image list")
    image_links = await page.locator("td > a").all()

    logger.info(f"found {len(image_links)} links")

    tasks = []
    for image in image_links:
        href = await image.get_attribute("href")
        image_page_url = urljoin(page.url, href)
        tasks.append(asyncio.create_task(visit_subpage_and_download_artwork(browser, target_dir, image_page_url)))

    await tqdm.gather(*tasks, desc="downloading images")

async def main():
    artist = args.artist

    target_dir = Path(artist)

    target_dir.mkdir(exist_ok=True)

    artist_url = url_map[artist]

    logger.info(f"downloading {artist}'s artwork from {artist_url}")

    async with async_playwright() as playwright:
        await download_artist(playwright, target_dir, artist_url)

    logger.info(f"SUCCESSFULLY DOWNLOADED: {successfully_downloaded}")
    logger.info(f"WITH ERRORS {len(errors)}")
    for url, error in errors:
        logger.info(f"{url}: {error}")

asyncio.run(main())
