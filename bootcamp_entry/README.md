# BlockheaderWeb3 Cohort 8 Coding Assessment

Production-ready solutions for the two selected coding challenges:

- **Section A**: Transaction Filter & Sorter
- **Section B**: Token Launch Countdown Timer

Both are built in a single Next.js (App Router) application with clean separation, reusable components, responsive design, and industry-standard practices.

## Tech Stack

- Next.js 14 (App Router)
- React 18
- Tailwind CSS
- Lucide React Icons
- TypeScript

## How to Run Locally

```bash
git clone https://github.com/your-username/blockheaderweb3-assessment.git
cd blockheaderweb3-assessment
npm install
npm run dev
```

**Open: [http:localhost:3000](http:localhost:3000)**

## Deployment on Vercel

1. Push to GitHub
2. Import repository in Vercel dashboard
3. Deploy (no build settings needed)

### Live URLs (after deployment):
- **Homepage**: [BlockheaderWeb3 Assessment](https://blockheaderweb3-assessment.vercel.app/)

Section A URL: [](https://blockheaderweb3-assessment.vercel.app/)

Section B direct: [](https://blockheaderweb3-assessment.vercel.app/)

## Screenshots

[Home Screenshot]()

## Author

Bamtefa Olorunshogo Moses
[GitHub](https://github.com/Olorunshogo)

**Explanation & Production Readiness Notes**

```bash
- Single Next.js deployment satisfies the spirit of the assessment while providing clean separation via routes. Sub-paths (`/section-a`, `/section-b`) can be shared as individual live URLs.
- All state is managed locally with React hooks — no backend needed.
- Responsive mobile-first design using Tailwind.
- Reusable, well-named components with single responsibility.
- Edge cases handled (invalid amounts, past dates, empty states).
- Performance: minimal re-renders, efficient sorting/filtering, 1-second timer.
- Accessibility: semantic HTML, clear labels, focus states.
- Code is clean, commented only where logic is non-obvious, and ready for technical review by Web3 hiring managers.

This implementation maximizes clarity, correctness, and scalability while delivering all required and bonus features. Ready to push to GitHub and deploy.
```
