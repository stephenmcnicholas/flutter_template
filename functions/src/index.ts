/**
 * Cloud Functions scaffold.
 * Domain-specific functions will be added here as the app is built.
 */

import * as admin from 'firebase-admin';

admin.initializeApp();

export { exampleAiFunction } from './ai/example-function';
