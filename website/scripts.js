document.addEventListener('DOMContentLoaded', () => {
    const navLinks = document.querySelectorAll('.nav-link');
    const pages = document.querySelectorAll('.page');
    const leftArrows = document.querySelectorAll('.left-arrow');
    const rightArrows = document.querySelectorAll('.right-arrow');
    const scrollArrows = document.querySelectorAll('.scroll-arrow');
    const screenWidthPopup = document.getElementById('screen-width-popup');
    const mobilePopup = document.getElementById('mobile-popup');
    const closeWidthPopupBtn = document.getElementById('close-width-popup');
    const closeMobilePopupBtn = document.getElementById('close-mobile-popup');
    let currentPageIndex = 0;
    const arrowShown = { 1: false, 2: false };
    const scrollDepth = 250;
    const triggerWidth = 875;

    // Function to update the position of the arrows based on viewport height
    function updateArrowPositions() {
        const arrowTopPosition = (window.innerHeight / 2) + 10;
        leftArrows.forEach(arrow => {
            arrow.style.position = 'fixed';
            arrow.style.left = '10px';
            arrow.style.top = `${arrowTopPosition}px`;
        });
        rightArrows.forEach(arrow => {
            arrow.style.position = 'fixed';
            arrow.style.right = '10px';
            arrow.style.top = `${arrowTopPosition}px`;
        });
    }

    // Show or hide pop-ups based on screen width and device type
    function checkScreenWidth() {
        const screenWidth = window.innerWidth;
        const isMobile = /Mobi|Tablet|iPad|iPhone/.test(navigator.userAgent);
    
        if (screenWidth < triggerWidth && !sessionStorage.getItem('widthPopupClosed') && !isMobile) {
            screenWidthPopup.style.display = 'block';
        } else {
            screenWidthPopup.style.display = 'none';
        }
    
        if (isMobile && !sessionStorage.getItem('mobilePopupClosed')) {
            mobilePopup.style.display = 'block';
        } else {
            mobilePopup.style.display = 'none';
        }
    }
    

    // Update arrow positions on load and on window resize
    updateArrowPositions();
    checkScreenWidth();
    window.addEventListener('resize', () => {
        updateArrowPositions();
        checkScreenWidth();
    });

    // Close pop-up handlers
    closeWidthPopupBtn.addEventListener('click', () => {
        screenWidthPopup.style.display = 'none';
        sessionStorage.setItem('widthPopupClosed', 'true');
    });

    closeMobilePopupBtn.addEventListener('click', () => {
        mobilePopup.style.display = 'none';
        sessionStorage.setItem('mobilePopupClosed', 'true');
    });

    function showPage(index) {
        pages.forEach((page, i) => {
            page.style.display = i === index ? 'block' : 'none';
        });
        navLinks.forEach((link, i) => {
            link.classList.toggle('active', i === index);
        });
        if ((index === 1 || index === 2) && !arrowShown[index]) {
            scrollArrows.forEach(arrow => arrow.style.display = 'block');
        } else {
            scrollArrows.forEach(arrow => arrow.style.display = 'none');
        }
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

    document.addEventListener('scroll', () => {
        if (currentPageIndex === 1 || currentPageIndex === 2) {
            if (window.scrollY > scrollDepth) {
                arrowShown[currentPageIndex] = true;
                scrollArrows.forEach(arrow => arrow.style.display = 'none');
            }
        }
    });

    showPage(currentPageIndex);

    const options = {
        root: null,
        rootMargin: '0px',
        threshold: 0.1
    };

    const loadMap = (entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const iframe = document.querySelector("#interactive-maps iframe");
                if (!iframe.src) {
                    iframe.src = "nc_counties_map.html";
                }
                observer.unobserve(entry.target);
            }
        });
    };

    const observer = new IntersectionObserver(loadMap, options);
    const target = document.querySelector("#new-electorate");
    observer.observe(target);
});
