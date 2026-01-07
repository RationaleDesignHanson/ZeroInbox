#!/usr/bin/env node
import { basicFixtures } from '@zero/test-fixtures';
import { ActionTestRunner } from './runner';

async function main() {
  const runner = new ActionTestRunner();
  const summary = await runner.runSuite(basicFixtures);

  const status = summary.failed === 0 ? 'PASSED' : 'FAILED';
  console.log(`Suite ${status}: ${summary.passed}/${summary.totalTests} passed`);
  summary.results.forEach((result) => {
    const mark = result.passed ? '✅' : '❌';
    console.log(
      `${mark} ${result.fixtureName} (intent ${result.actualIntent} @ ${result.actualConfidence.toFixed(2)}, action ${result.actualAction})`
    );
  });

  process.exit(summary.failed > 0 ? 1 : 0);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

