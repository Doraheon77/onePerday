import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
  try {
    const guideSample = await prisma.$queryRaw`
      SELECT * FROM "nutrient_guide" LIMIT 3
    `;
    console.log('Sample from nutrient_guide:', guideSample);

    const standardSample = await prisma.$queryRaw`
      SELECT * FROM "nutrientStandards" LIMIT 3
    `;
    console.log('Sample from nutrientStandards:', standardSample);

  } catch (err) {
    console.error('Error querying samples:', err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
