import { ConnectorConfig, DataConnect, OperationOptions, ExecuteOperationResponse } from 'firebase-admin/data-connect';

export const connectorConfig: ConnectorConfig;

export type TimestampString = string;
export type UUIDString = string;
export type Int64String = string;
export type DateString = string;


export interface Course_Key {
  id: UUIDString;
  __typename?: 'Course_Key';
}

export interface CreateNewCourseData {
  course_insert: Course_Key;
}

export interface CreateNewCourseVariables {
  title: string;
  description: string;
  instructorId: UUIDString;
}

export interface EnrollUserInCourseData {
  enrollment_insert: Enrollment_Key;
}

export interface EnrollUserInCourseVariables {
  studentId: UUIDString;
  courseId: UUIDString;
}

export interface Enrollment_Key {
  studentId: UUIDString;
  courseId: UUIDString;
  __typename?: 'Enrollment_Key';
}

export interface GetCoursesForUserData {
  user?: {
    courses_via_Enrollment: ({
      id: UUIDString;
      title: string;
      description: string;
    } & Course_Key)[];
  };
}

export interface GetCoursesForUserVariables {
  userId: UUIDString;
}

export interface ListAllCoursesData {
  courses: ({
    id: UUIDString;
    title: string;
    description: string;
    instructor: {
      id: UUIDString;
      displayName: string;
    } & User_Key;
  } & Course_Key)[];
}

export interface Material_Key {
  id: UUIDString;
  __typename?: 'Material_Key';
}

export interface Module_Key {
  id: UUIDString;
  __typename?: 'Module_Key';
}

export interface User_Key {
  id: UUIDString;
  __typename?: 'User_Key';
}

/** Generated Node Admin SDK operation action function for the 'CreateNewCourse' Mutation. Allow users to execute without passing in DataConnect. */
export function createNewCourse(dc: DataConnect, vars: CreateNewCourseVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateNewCourseData>>;
/** Generated Node Admin SDK operation action function for the 'CreateNewCourse' Mutation. Allow users to pass in custom DataConnect instances. */
export function createNewCourse(vars: CreateNewCourseVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateNewCourseData>>;

/** Generated Node Admin SDK operation action function for the 'ListAllCourses' Query. Allow users to execute without passing in DataConnect. */
export function listAllCourses(dc: DataConnect, options?: OperationOptions): Promise<ExecuteOperationResponse<ListAllCoursesData>>;
/** Generated Node Admin SDK operation action function for the 'ListAllCourses' Query. Allow users to pass in custom DataConnect instances. */
export function listAllCourses(options?: OperationOptions): Promise<ExecuteOperationResponse<ListAllCoursesData>>;

/** Generated Node Admin SDK operation action function for the 'EnrollUserInCourse' Mutation. Allow users to execute without passing in DataConnect. */
export function enrollUserInCourse(dc: DataConnect, vars: EnrollUserInCourseVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<EnrollUserInCourseData>>;
/** Generated Node Admin SDK operation action function for the 'EnrollUserInCourse' Mutation. Allow users to pass in custom DataConnect instances. */
export function enrollUserInCourse(vars: EnrollUserInCourseVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<EnrollUserInCourseData>>;

/** Generated Node Admin SDK operation action function for the 'GetCoursesForUser' Query. Allow users to execute without passing in DataConnect. */
export function getCoursesForUser(dc: DataConnect, vars: GetCoursesForUserVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetCoursesForUserData>>;
/** Generated Node Admin SDK operation action function for the 'GetCoursesForUser' Query. Allow users to pass in custom DataConnect instances. */
export function getCoursesForUser(vars: GetCoursesForUserVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetCoursesForUserData>>;

