document.addEventListener('DOMContentLoaded', () => {
    const navLinks = document.querySelectorAll('.nav-link');
    const pages = document.querySelectorAll('.page');
    const leftArrows = document.querySelectorAll('.left-arrow');
    const rightArrows = document.querySelectorAll('.right-arrow');
    let currentPageIndex = 1;

    function showPage(index) {
        pages.forEach((page, i) => {
            page.style.display = i === index ? 'block' : 'none';
        });
        navLinks.forEach((link, i) => {
            link.classList.toggle('active', i === index);
        });
    }

    function nextPage() {
        if (currentPageIndex < pages.length - 1) {
            currentPageIndex++;
            showPage(currentPageIndex);
        }
    }

    function previousPage() {
        if (currentPageIndex > 0) {
            currentPageIndex--;
            showPage(currentPageIndex);
        }
    }

    navLinks.forEach((link, index) => {
        link.addEventListener('click', (event) => {
            event.preventDefault();
            currentPageIndex = index;
            showPage(currentPageIndex);
        });
    });

    document.addEventListener('keydown', (event) => {
        if (event.key === 'ArrowRight' || event.key === ' ') {
            nextPage();
        } else if (event.key === 'ArrowLeft') {
            previousPage();
        }
    });

    rightArrows.forEach(arrow => {
        arrow.addEventListener('click', nextPage);
    });

    leftArrows.forEach(arrow => {
        arrow.addEventListener('click', previousPage);
    });

    // Show the first page by default
    showPage(currentPageIndex);
});
